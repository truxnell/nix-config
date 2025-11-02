#!/usr/bin/env python3
"""
----------------------------------------------------------------------------------
Get RAPT Pill Telemetry data from IoT RESTful API. Publish to MQTT broker.

For now, this only handles RAPT pill.

Must create an API Secret at https://app.rapt.io/account/apisecrets and then set
the following environment variables with your details:

export RAPT_API_USER=\"raptuser@email.com\"
export RAPT_API_PASS=\"api_secret\"

# Note: A MQTT server is required. Create the following environment variable with
# IP address of your server/broker:
export MQTT_IP=\"192.168.1.1\"

# If have a username/password on MQTT broker (and you should), define the following
# with your details. Otherwise do not define this envirnoment variable and no
# authentication will be used.
export MQTT_AUTH=\"{'username':\\\"mymqttuser\\\", 'password':\\\"mymqttpw\\\"}\"

The script works as follows,

 1. Get a token to access data
 2. If successful, get Hydrometer data for all Hydrometers
 3. If any new data:
  * Construct a JSON payload
  * Send payload to the MQTT server
 4. Sleep for X minutes before checking for a new measurement

# How to run

First install Python dependencies

 pip install paho-mqtt requests python-dateutilxs

Run the script,

 python rapt-mqtt.py -n 30 -f -s

"""

# For future Python3 compatibility:
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import time
import os
import random
import sys
import logging as lg
import argparse
import traceback

from datetime import datetime
from datetime import timedelta
from datetime import timezone
from dateutil.parser import isoparse

import json
import paho.mqtt.publish as publish
import requests
from ast import literal_eval


### Constants
baseURLAPI = "https://api.rapt.io/api"
URLtoken = "https://id.rapt.io/connect/token"

# LOG Settings
lg.basicConfig(level=lg.INFO)
LOG = lg.getLogger()


def cmdline_args():
    # from https://gist.github.com/ahogen/6fc1760bbf924f4ee6857a08e4fea80a

    # Make parser object
    #@@@#p = argparse.ArgumentParser(description=__doc__,
    #@@@#    formatter_class=argparse.RawDescriptionHelpFormatter)
    p = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter)

    #p.add_argument("required_positional_arg",
    #               help="desc")
    #p.add_argument("required_int", type=int,
    #               help="req number")
    #p.add_argument("--log_none", action="store_true",
    #               help="include to disable logging")
    p.add_argument("-v", "--verbosity", type=int, choices=[0,1,2], default=0,
                   help="increase output verbosity (default: %(default)s)")

    p.add_argument("-n", "--interval", type=int, default=15,
                   help="run interval in minutes (default: %(default)s)")

    tempgroup = p.add_mutually_exclusive_group(required=True)
    tempgroup.add_argument('-f','--fahrenheit',action="store_true",help="temperature is in Fahrenheit")
    tempgroup.add_argument('-c','--celsius',action="store_true",help="temperature is in Celsius")

    tempdensity = p.add_mutually_exclusive_group(required=True)
    tempdensity.add_argument('-s','--specific',action="store_true",help="density is in Specific Gravity/SG")
    tempdensity.add_argument('-b','--brix',action="store_true",help="density is in Brix")
    tempdensity.add_argument('-p','--plato',action="store_true",help="density is in Plato")

    return(p.parse_args())

def GetHydrometers(tk, verbosity=0):

    URL = baseURLAPI + "/Hydrometers/GetHydrometers"

    headers = {
        "accept": "application/json",
        "Authorization": "Bearer " + tk
    }

    resp = requests.get(URL, headers = headers)

    if (resp.status_code != 200):
        raise RuntimeError("GetHydrometers(): " + str(resp.status_code) + "  " + str(resp.text))

    data = json.loads(resp.text)
    if (verbosity >= 2):
        LOG.info('Hydrometers: ' + str(resp.text))
        LOG.info('Success')

    return data

def getRAPTToken(ur, pw):

    headers = {
        "Content-Type": "application/x-www-form-urlencoded"
    }

    params = {
        "client_id": "rapt-user",
        "grant_type": "password",
        "username": ur,
        "password": pw
    }

    #@@@#resp = requests.post(URL, headers = headers, data=json.dumps(params))
    resp = requests.post(URLtoken, headers = headers, data=params)

    if (resp.status_code != 200):
        raise RuntimeError("getRAPTToken(): " + str(resp.status_code) + "  " + str(resp.text))

    tk = json.loads(resp.text)['access_token']
    #@@@#LOG.info('token: ' + str(tk))
    #@@@#LOG.info('token: ' + str(resp.text))
    #@@@#LOG.info('Success')

    return tk


def publishData(name, data, mqttConfig, verbosity=0):

    msgs = []

    # Create message                                            QoS   Retain message
    msgs.append(("rapt/pill/{}".format(name), json.dumps(data), 2,    1))

    # Send message via MQTT server
    publish.multiple(msgs, hostname=mqttConfig['host'], port=mqttConfig['port'], auth=mqttConfig['auth'], protocol=4)

    if verbosity >= 1:
        LOG.info("New Data from RAPT Pill '{}': temp={}F/{}C  sg={}/plato={}/Brix={}  batt={}%  rssi={}dBm time={}".format(
            name, data["temperature_fahrenheit"], data["temperature_celsius"],
            data["specific_gravity"], data["plato"], data["brix"], data["battery"], data["rssi"],
            data["lastActivityTime"]))


def oldData(name, data, verbosity=0):

    if verbosity >= 2:
        LOG.info("only OLD Data from RAPT Pill '{}': temp={}F/{}C  sg={}/plato={}/Brix={}".format(
            name, data["temperature_fahrenheit"], data["temperature_celsius"], data["specific_gravity"], data["plato"], data["brix"]))


def main(args):

    #@@@#if (not args.log_none):
    if (True):
        # LOG Settings
        #
        # Create handlers
        c_handler = lg.StreamHandler()
        f_handler = lg.FileHandler('/tmp/rapt-mqtt-{}.log'.format(os.getpid()))
        c_handler.setLevel(lg.DEBUG)
        f_handler.setLevel(lg.INFO)

        # Create formatters and add it to handlers
        c_format = lg.Formatter('%(name)s - %(levelname)s - %(message)s')
        f_format = lg.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        c_handler.setFormatter(c_format)
        f_handler.setFormatter(f_format)

        # Add handlers to the logger
        LOG.addHandler(c_handler)
        LOG.addHandler(f_handler)

    # RAPT Settings
    raptConfig = {
        'user': os.environ.get('RAPT_API_USER'),
        'pwrd': os.environ.get('RAPT_API_PASS')
    }

    # MQTT Settings
    mqttConfig = {
        'host': os.getenv('MQTT_IP', '127.0.0.1'),
        'port':int(os.getenv('MQTT_PORT', 1883)),
        'auth': literal_eval(os.getenv('MQTT_AUTH', "None")),
        'debug': os.getenv('MQTT_DEBUG', False),
    }

    if not raptConfig['user'] or not raptConfig['pwrd']:
        errmsg = ("Must set the following environment variables with your specifics:\n" +
                  '   export RAPT_API_USER="raptuser@email.com"\n' +
                  '   export RAPT_API_PASS="api_secret"')
        LOG.error(errmsg)
        sys.exit(-1)

    try:
        # Create a datetime object from args.interval minutes ago.
        # Be sure that it has TZ set to UTC for comparison.
        # The +1 minute makes sure that execution time does not make us miss a data point
        then = datetime.utcnow() - timedelta(minutes=args.interval+1)
        then = then.replace(tzinfo=timezone.utc)

        lastTime = {}
        while(1):
            tk = getRAPTToken(raptConfig['user'], raptConfig['pwrd'])

            for hydro in GetHydrometers(tk, verbosity=args.verbosity):
                # Check if the RAPT Pill with this name has a saved
                # time in lastTime[]. If not, initialize it to then
                # which is created when the script is first run.
                if not hydro["name"] in lastTime.keys():
                    lastTime[hydro["name"]] = then

                # get the lastActivityTime of this data
                lat = isoparse(hydro["lastActivityTime"])

                # convert temperatures - since fahrenheit and celsius
                # are mutually exclusive, if not fahrenheit then must
                # be celsius.
                if (args.fahrenheit):
                    # temperature units are fahrenheit so convert to celsius
                    temperature_fahrenheit = hydro["temperature"]
                    temperature_celsius = (temperature_fahrenheit - 32) * 5/9
                else:
                    # temperature units are celsius so convert to fahrenheit
                    temperature_celsius = hydro["temperature"]
                    temperature_fahrenheit = (temperature_celsius * 9/5) + 32

                if (args.specific):
                    # gravity is in specific gravity. convert to plato & Brix
                    specific_gravity = round(hydro["gravity"]/1000,4)
                    # from https://www.brewersfriend.com/plato-to-sg-conversion-chart/
                    degree_plato = 135.997*pow(specific_gravity, 3) - 630.272*pow(specific_gravity, 2) + 1111.14*specific_gravity - 616.868
                    # from https://www.brewersfriend.com/brix-converter/
                    degree_brix = (((182.4601 * specific_gravity-775.6821) * specific_gravity+1262.7794) * specific_gravity-669.5622)

                if (args.brix):
                    # gravity is in Brix, convert to specific gravity and plato
                    degree_brix = hydro["gravity"]
                    # from https://www.brewersfriend.com/brix-converter/
                    specific_gravity = (degree_brix / (258.6-((degree_brix / 258.2)*227.1))) + 1
                    # from https://www.brewersfriend.com/plato-to-sg-conversion-chart/
                    degree_plato = 135.997*pow(specific_gravity, 3) - 630.272*pow(specific_gravity, 2) + 1111.14*specific_gravity - 616.868

                if (args.plato):
                    # gravity is in Plato, convert to specific gravity and Brix
                    degree_plato = hydro["gravity"]
                    # from https://www.brewersfriend.com/plato-to-sg-conversion-chart/
                    specific_gravity = 1+(degree_plato / (258.6 - ((degree_plato/258.2)*227.1)))
                    # from https://www.brewersfriend.com/brix-converter/
                    degree_brix = (((182.4601 * specific_gravity-775.6821) * specific_gravity+1262.7794) * specific_gravity-669.5622)

                data = {
                    "specific_gravity": "{:.4f}".format(specific_gravity),
                    "plato": "{:.2f}".format(degree_plato),
                    "brix": "{:.2f}".format(degree_brix),
                    "temperature_celsius": "{:.1f}".format(temperature_celsius),
                    "temperature_fahrenheit": "{:.1f}".format(temperature_fahrenheit),
                    "battery": "{:.1f}".format(hydro["battery"]),
                    "rssi": "{:.1f}".format(hydro["rssi"]),
                    "lastActivityTime": "{}".format(hydro["lastActivityTime"])
                }

                # If the lastActivityTime is newer than the last time
                # this data was processed, then consider it new
                # data. Otherwise ignore the old data.
                if (lat > lastTime[hydro["name"]]):
                    # Save this lastActivityTime for comparision next time
                    lastTime[hydro["name"]] = lat

                    # Publish to MQTT broker
                    publishData(hydro["name"], data, mqttConfig, verbosity=args.verbosity)

                else:
                    oldData(hydro["name"], data, verbosity=args.verbosity)


            # Wait until next scan period
            time.sleep(args.interval*60)
    except KeyboardInterrupt:
        LOG.info("Received Ctrl-C. Exiting...")
    except RuntimeError as err:
        errmsg = "ERROR {}".format(err)
        LOG.error(errmsg)
    except BaseException as error:
        errmsg = 'An unexpected exception occurred: {}\n'.format(error) + repr(error)
        LOG.error(errmsg)
        traceback.print_exc()

if __name__ == '__main__':
    try:
        args = cmdline_args()
    except:
        print(__doc__)
        sys.exit(-2)

    main(args)
