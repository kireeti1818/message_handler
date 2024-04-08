require 'socket'
require 'yaml'
require 'json'
require "./client.rb"  # Require the client module defined in client.rb

# Method to handle user options (login or create new user)
def options()
    option = nil
    username_server = nil
    port_server = nil
    
    loop do
        print "1) Login\n2) Create new user\nEnter your sign-in option: "
        option = gets.strip().to_i
        
        if option == 1
            print "Enter username: "
            loop do
                config = YAML.load_file('config.yaml')
                usernamefinder = false
                username_server = gets.strip()
                
                # Check if the username exists in the config file
                if config[username_server].nil?
                    print "Username does not exist\nEnter correct username: "
                    usernamefinder = true 
                end 
                
                # If username is found, get the port number associated with it
                if usernamefinder == false
                    port_server = config[username_server].to_i
                    break
                end
            end
            break
        elsif option == 2
            # Create new user
            loop do 
                finduser = true
                print "Enter username: "
                username_server = gets.strip()
                
                # Check if the username already exists
                File.open('config.yaml', 'r') do |file|
                    file.each_line do |line|
                        name = line.split(":")[0].strip()
                        if username_server == name
                            puts "User already exists...."
                            finduser = false
                        end
                    end
                end
                
                if finduser == true
                    break
                end
            end
            
            # Get an unused port number
            loop do 
                finduser = true
                print "Enter port number: "
                port_server = gets.strip().to_i
                
                # Check if the port number is already in use
                File.open('config.yaml', 'r') do |file|
                    file.each_line do |line|
                        portnumber = line.split(":")[1].strip()
                        if portnumber == port_server.to_s
                            puts "Port already in use...."
                            finduser = false
                        end
                    end
                end
                
                if finduser == true
                    break
                end
            end
            
            # Write the new username and port number to the config file
            new_data = {
                username_server.to_sym => port_server
            }
            yaml_data = YAML.dump(new_data)
            yaml_data.sub!(/^---\s\:/, '') 

            File.open('config.yaml', 'a') do |file|
                file.write(yaml_data)
            end
            break
        else 
            puts "[+] Wrong option..."
        end 
    end
    
    return port_server, username_server
end 

# Class to handle server operations
class Server
    @server = nil
    
    def initialize(port_server)
        @server = TCPServer.new(port_server)
        puts "Server started. Waiting for connections..."
    end
    
    # Method to handle client connections
    def client_handler(username_to_sent, line, client_connected_to_server)
        port = Client.get_username_port(username_to_sent)
        Client.socket(port)
        Client.send_message(line)
        response = Client.receive_message()
        puts response
        client_connected_to_server.puts(response)
    end
    def close()
        @server.close()
    end
    # Method to handle incoming messages from clients
    def message_handler(username_server)
        loop do
            client_connected_to_server = @server.accept  # Wait for a client to connect
            client_connected_to_server.puts("__connected__")
            puts "Client connected from #{client_connected_to_server.peeraddr}"
            
            # Read data from the client
            line = client_connected_to_server.gets
            break if line.nil? 
            data = JSON.parse(line)  
            puts "Received: #{data}"
            username_to_sent = nil
            no_need_to_send = false

            # Process the received message and determine the recipient
            if data["end_user"] == nil || data["end_user"] == ""
                line = "#{username_server} received message from #{data["sent_user"]}"
                puts "#{data["message"]} received from #{username_server}"
                client_connected_to_server.puts(line)
            elsif data["intermediate_users"].length == 0
                username_to_sent = data["end_user"]
                data["end_user"] = nil
                client_handler(username_to_sent, data.to_json, client_connected_to_server)
            else
                username_to_sent = data["intermediate_users"][0]
                data["intermediate_users"] = data["intermediate_users"].drop(1)
                client_handler(username_to_sent, data.to_json, client_connected_to_server)
            end
            client_connected_to_server.close  
        end
    end
end


server=nil
begin
    port,username = options()
    server = Server.new(port)
    server.message_handler(username)
rescue
    puts "error occured"
    server.close()
end