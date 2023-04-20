extends Node

# Default game server port. Can be any number between 1024 and 49151.
const DEFAULT_PORT = 28960
const MAX_CLIENTS = 6

var server = null
var client = null

var ip_address = ""
var current_player_username = ""

var client_connected_to_server = false

var networked_object_name_index = 0 setget networked_object_name_index_set
puppet var puppet_networked_object_name_index = 0 setget puppet_networked_object_name_index_set

onready var client_connection_timeout_timer = Timer.new()

func _ready() -> void:
	add_child(client_connection_timeout_timer)
	client_connection_timeout_timer.wait_time = 10
	client_connection_timeout_timer.one_shot = true
	
	client_connection_timeout_timer.connect("timeout", self, "_client_connection_timeout")
	
	if OS.get_name() == "Windows":
		ip_address = IP.get_local_addresses()[3]
	elif OS.get_name() == "Android":
		ip_address = IP.get_local_addresses()[0]
	else:
		ip_address = IP.get_local_addresses()[3]
	
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") and not ip.ends_with(".1"):
			ip_address = ip
	
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	get_tree().connect("connection_failed", self, "_connection_failed")
	

func create_server() -> bool:
	server = NetworkedMultiplayerENet.new()
	var err = server.create_server(DEFAULT_PORT, MAX_CLIENTS)
	if err == OK:
		get_tree().set_network_peer(server)
		Global.instance_node(load("res://server_advertiser/Server_advertiser.tscn"), self)
		return true
	else:
		printerr("failing! err=%s :create_server"%err)
		return false
	

func join_server() -> bool:
	client = NetworkedMultiplayerENet.new()
	var err = client.create_client(ip_address, DEFAULT_PORT)
	if err == OK:
		get_tree().set_network_peer(client)
		client_connection_timeout_timer.start()
		return true
	else:
		printerr("failing! err=%s :join_server"%err)
		return false
	

func reset_network_connection() -> void:
	if get_tree().has_network_peer():
		get_tree().network_peer.close_connection()
		get_tree().network_peer = null

func _connected_to_server() -> void:
	print("Successfully connected to the server")
	
	client_connected_to_server = true

func _server_disconnected() -> void:
	print("Disconnected from the server")
	
	
	for child in get_tree().get_nodes_in_group("Net"):
		if child.is_in_group("Net"):
			child.queue_free()
	
	reset_network_connection()
	
	var prompt = Global.instance_node(load("res://simple_prompt/Simple_prompt.tscn"), GlobalUI)
	prompt.set_text("Disconnected from server")

func _client_connection_timeout():
	if client_connected_to_server == false:
		print("Client has been timed out")
		
		reset_network_connection()
		
		var connection_timeout_prompt = Global.instance_node(load("res://simple_prompt/Simple_prompt.tscn"), GlobalUI)
		connection_timeout_prompt.set_text("Connection timed out")

func _connection_failed():
	for child in get_tree().get_nodes_in_group("Net"):
		if child.is_in_group("Net"):
			child.queue_free()
	
	reset_network_connection()
	
	var connection_timeout_prompt = Global.instance_node(load("res://simple_prompt/Simple_prompt.tscn"), GlobalUI)
	connection_timeout_prompt.set_text("Connection failed")

func puppet_networked_object_name_index_set(new_value):
	networked_object_name_index = new_value

func networked_object_name_index_set(new_value):
	networked_object_name_index = new_value
	
	if get_tree().is_network_server():
		rset("puppet_networked_object_name_index", networked_object_name_index)

	

