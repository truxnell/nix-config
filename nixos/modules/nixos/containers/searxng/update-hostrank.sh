
# template codeblock for

# blank out existing files
echo "" > higher
echo "" > lower
echo "" > remove

# services.searx.settings.hostnames.high_priority|low_priority
# services.searx.settings.hostnames.low_priority
# services.searx.settings.hostnames.remove

function parse_goggle {
  local url="$1"
  local temp_file=$(mktemp)
  
  # Download the source once
  if ! curl -s "$url" | grep -v '^!' > "$temp_file"; then
    echo "Failed to download $url" >&2
    rm -f "$temp_file"
    return 1
  fi
  
  # Function to process each pattern and output file
  process_pattern() {
    local pattern="$1"
    local output_file="$2"
    grep -E "$pattern" "$temp_file" | 
      sed -n -E 's/\r$//; 
                s/^[^#]*(site|domain)=([^,[:space:]"'\'']+)($|,.*$)/"?\2"/p;
                s/^[^#]*(site|domain)="([^"]+)"($|,.*$)/"?\2"/p;
                s/^[^#]*(site|domain)='\''([^'\'']+)'\''($|,.*$)/"?\2"/p' >> "$output_file"
    
    # Check if any domains were found and processed
    if [[ ! -s "$output_file" ]]; then
      echo "Warning: No domains found with pattern '$pattern'" >&2
    fi
  }
  
  # Calls process_pattern for each desired pattern and file
  process_pattern "boost=" "higher.nix"
  process_pattern "downrank" "lower.nix"
  process_pattern "discard" "remove.nix"
  
  # Clean up the temporary file
  rm -f "$temp_file"
}

# FMHY
# FMHY remove domains
curl -s https://raw.githubusercontent.com/fmhy/FMHYFilterlist/refs/heads/main/sitelist.txt | grep -v '^!' | sed 's/^/"?/' | sed 's/$/"/' >> remove
curl -s https://raw.githubusercontent.com/fmhy/FMHYFilterlist/refs/heads/main/sitelist-plus.txt | grep -v '^!' | sed 's/^/"?/' | sed 's/$/"/' >> remove

# Wikipedia perennial/etc
parse_goggle https://raw.githubusercontent.com/kynoptic/wikipedia-reliable-sources/refs/heads/main/wikipedia-reliable-sources.goggle

# few android related rankings
parse_goggle "https://raw.githubusercontent.com/gayolGate/gayolGate/8f26b202202e76896bce59d865c5e7d4c35d5855/goggle.txt"