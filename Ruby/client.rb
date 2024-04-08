require 'socket'
require 'yaml'
require 'json'

module Client
    @port_client = nil
    @username_client = nil
    @client = nil

    # Method to retrieve username and port from config file
    def self.get_username_port(username)
        @username_client = username
        File.open('config.yaml', 'r') do |file|
            file.each_line do |line|
                name = line.split(":")[0].strip()

                if @username_client == name
                    @port_client = line.split(":")[1].strip().to_i
                end
            end
        end

        if !@port_client.nil?
            return @port_client
        else 
            puts "User does not exist."
            return nil
        end
    end

    # Method to create socket connection
    def self.socket(port) 
        begin
            @client = TCPSocket.new('localhost', port)
        rescue 
            puts "Error while creating socket"
        end
        if @client.gets.strip()=="__connected__"
            puts "[+] Connected to server"
        end
    end

    # Method to send a message to the server
    def self.send_message(message_json)
        @client.puts(message_json)
    end

    # Method to receive a message from the server
    def self.receive_message()
        @client.gets()
    end

    # Method to handle user input and send message to server
    def self.message_handler() 
        print "Enter to whom #{@username_client} wants to send the message : "
        endUserName = gets.strip()
        print "Enter intermediate users : "
        intermediateUsers = gets.strip().split(" ").to_a
        message = nil
        
        loop do
            print "Enter message : "
            message = gets.strip()
            if (message.strip().empty?)
                next
            else
                break
            end
        end
    
        data = {
            "message" => message,
            "sent_user" => @username_client,
            "intermediate_users" => intermediateUsers,
            "end_user" => endUserName
        }
        json_message = data.to_json #converting hash to json format
        @client.puts(json_message)
        
        puts @client.gets
    end
end

# Entry point of the script
if __FILE__ == $0
    port = nil
    
    # Loop to get username and port from user input
    loop do 
        print "Enter username : "
        username = gets.strip()
        port = Client.get_username_port(username)
        if port != nil
            break
        end
    end
    
    # Loop to create socket connection and handle messages
    loop do
        Client.socket(port)
        Client.message_handler()
    end
end

