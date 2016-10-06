###
### Compile symbols.in to produce symbols.txt
### 


## 
## Parsing/unparsing word specifications:
## 

def unparse_word(written, spoken=nil, properties=nil)
  result  =       escape(written)
  result += ":" + escape(spoken)     if spoken or properties
  result += ":" + escape(properties) if properties 

  return result
end

def escape(text)
  return "" unless text
  text.gsub(/[#:\\]/) { |x| '\\'+x }
end


def parse_word(line)
  line = line.gsub(/^(([^\#\\]|\\.|\\\Z)*).*/, '\1').chomp   # eat comments, EOL
  return nil if line =~ /^\s*$/

  return (line.scan(/(?:\A|:)(([^\:\\]|\\.|\\\Z|)*)/)
         .collect { |f,| f.gsub(/\\(.)/, '\1').strip })
end



##
## Handling overridden symbols:
##

Overridden_map = {}

def overridden(written, spoken)
  Overridden_map["#{written}\n#{spoken}"]
end

def override(written, spoken)
  Overridden_map["#{written}\n#{spoken}"]= true
end

    
def process_definition(symbol, name, properties)
  if overridden(symbol, name)
    puts "#" + unparse_word(symbol, name, properties) + 
      "   # OVERRIDDEN"
  else
    puts unparse_word(symbol, name, properties)
  end
end



##
##
## 

def process_symbol(left_symbol, name, right_symbol=nil)
  puts

  if right_symbol
    # We have a "bracket":
    process_definition(left_symbol,  "open #{name}",  "p")
    process_definition(right_symbol, "close #{name}", "s")

    process_definition(left_symbol,  "left #{name}",  "t")
    process_definition(right_symbol, "right #{name}", "t")

    return if left_symbol != right_symbol
  end
  
  stand_alone_name = name
  stand_alone_name = "#{name} op" if left_symbol.length == 1

  process_definition(left_symbol, stand_alone_name, nil)
  process_definition(left_symbol, "tight #{name}",  "t")
  
#  process_definition(name, "written #{name}", nil) if name !~ / /
#  process_definition(name, "un#{name}", nil) if name !~ / /
  process_definition(name, "written #{name}", "alt(#{name})") if name !~ / /
end



##
## Main routine:
## 

puts <<HEADER
### 
### This file automatically generated by generate_symbols.rb!  Do not edit!
### 

HEADER


override_section = true

for line in ARGF
  line = line.rstrip

  if override_section
    puts line
    override_section = false if line == "##### SYMBOLS"
    
    written, spoken, properties = parse_word(line)
    override(written, spoken) if written
    
    next
  end
  
  written, spoken, properties = parse_word(line)
  next unless written
  
  process_symbol(written, spoken, properties)
end