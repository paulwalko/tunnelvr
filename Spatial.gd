extends Spatial

# Stuff to do:

# Approaching the networking (also to do with undo function)
# sketchsystem.sharexcdrawingovernetwork

# * implement deleteXC
# * should give the other player a position near to me:  $SketchSystem.rpc_id(id, "sketchsystemfromdict", $SketchSystem.sketchsystemtodict())
		
# * xctubesconn) == 0 should be a count of the tube types excluding connections to floor

# * pointertargettype as an enum

# * How is it going to work from planview?
#   -- this can be done from the plan view too, 
#   -- plot with front-culling so as to see inside the shapes, and plot with image textures on

# * tube has easy clicky ways to add in connecting lines between them (advancing the selected node after starting at a join)
# * confusion between papersheet and floordrawing being XCtype

# * getactivefloordrawing is duff.  we should record floor we are working with relative to an object, by connection

# * deal with positioning papersheet underlay
# * deal with connecting to the papersheet (bigger connectivities needed)
# * deal with seeing the paper drawing when you are inside 
# * active floor papersheet which we used for drawn texture (maybe on the ceiling)

# * check at loading gets the new paper bits in the right place

# * Make a consistent bit of cave in Ireby2

# * papertype should not be environment collision (just pointer collisions)
# * paper to be carried (nailed to same spot on the laser) when we move

# * remove reliance on rpc sync (a sync call in sketch system) connectiontoserveractive

# * refraction sphere for accurate pointing -- you hit the sphere and it then goes aligned with your eyes

# * highlight nodes under pointer system so it's global and simplifies colouring code (active node to be an overlay)

# * can set the type of the material (including invisible and no collision, so open on side)

# * grip on XCshape then click gets into rotate mode like with papersheets (but preserving upwardness)

# * godot docs.  assert returns null from the function it's in when you ignore it
# * check out HDR example https://godotengine.org/asset-library/asset/110

# * pointertargettypes should be an enum for itself
# * duplicate floor trimming out and place at different Z-levels
#			sketchsystem.rpc("xcdrawingfromdict", xcdrawing.exportxcrpcdata())
# * formalize the exact order of updates of positions of things so we don't get race conditions
# * transmit rpc_reliable when trigger released on the positioning of a papersheet

# https://developer.oculus.com/learn/hands-design-interactions/
# https://developer.oculus.com/learn/hands-design-ui/
# https://learn.unity.com/tutorial/unit-5-hand-presence-and-interaction?uv=2018.4&courseId=5d955b5dedbc2a319caab9a0#5d96924dedbc2a6236bc1191
# https://www.youtube.com/watch?v=gpQePH-Ffbw

# * moving floor up and down (also transmitted)
# *  XCpositions and new ones going through rsync?  
# * regexp option button to download all the files into the user directory.  
# * VR leads@skydeas1  and @brainonsilicon in Leeds (can do a trip there)

# * copy in more drawings as bits of paper size that can be picked up and looked at
# * think on how to remap the controls somehow.  Maybe some twist menus
# * CSG avatar head to have headtorch light that goes on or off and doesn't hit ceiling (gets moved down)

# * delete a tube that has no connections on it
# * systematically do the updatetubelinkpaths and updatetubelinkpaths recursion properly 

# * Bring in XCdrawings that are hooked to the centreline that will highlight when they get it
# * these cross sections are tied to the centrelinenodes and not the floor, and are prepopulated with the cross sections dimensions and tubes
# * Load and move the floor on load

# * clear up the laser pointer logic and materials
# * scan through other drawings on back of hand
# * check stationdrawnnode moves the ground up

# * Need to ask to improve the documentation on https://docs.godotengine.org/en/latest/classes/class_meshinstance.html#class-meshinstance-method-set-surface-material
# *   See also https://godotengine.org/qa/3488/how-to-generate-a-mesh-with-multiple-materials
# *   And explain how meshes can have their own materials, that are copied into material/0, and the material reappears if material/0 set to null
# * CSG mesh with multiple materials group should have material0, material1 etc

# * redo shiftfloorfromdrawnstations with nodes in the area of some kind (decide what to do about the scale)
	
export var hostipnumber: String = ""
export var hostportnumber: int = 8002
export var enablevr: = true
export var usewebsockets: = true

var perform_runtime_config = true
var ovr_init_config = null
var ovr_performance = null
var ovr_hand_tracking = null

onready var playerMe = $Players/PlayerMe

func checkloadinterface(larvrinterfacename):
	var available_interfaces = ARVRServer.get_interfaces()
	for x in available_interfaces:
		if x["name"] == larvrinterfacename:
			Tglobal.arvrinterface = ARVRServer.find_interface(larvrinterfacename)
			if Tglobal.arvrinterface != null:
				Tglobal.arvrinterfacename = larvrinterfacename
				print("Found VR interface ", x)
				return true
	return false

func setnetworkidnamecolour(player, networkID):
	player.networkID = networkID
	player.set_network_master(networkID)
	player.set_name("NetworkedPlayer"+String(networkID))
	var headcolour = Color.from_hsv((networkID%10000)/10000.0, 0.5 + (networkID%2222)/6666.0, 0.75)
	print("Head color ", headcolour)
	player.get_node("HeadCam/csgheadmesh/skullcomponent").material.albedo_color = headcolour
	
func _ready():
	print("  Available Interfaces are %s: " % str(ARVRServer.get_interfaces()));
	print("Initializing VR" if enablevr else "VR disabled");

	if checkloadinterface("OVRMobile"):
		print("found quest, initializing")
		ovr_init_config = load("res://addons/godot_ovrmobile/OvrInitConfig.gdns").new()
		ovr_performance = load("res://addons/godot_ovrmobile/OvrPerformance.gdns").new()
		ovr_hand_tracking = load("res://addons/godot_ovrmobile/OvrHandTracking.gdns").new();
		perform_runtime_config = false
		ovr_init_config.set_render_target_size_multiplier(1)
		if Tglobal.arvrinterface.initialize():
			get_viewport().arvr = true
			Engine.target_fps = 72
			Engine.iterations_per_second = 72
			print("  Success initializing Quest Interface.")
		else:
			Tglobal.arvrinterface = null

	if enablevr and checkloadinterface("Oculus"):
		print("  Found Oculus Interface.");
		if Tglobal.arvrinterface.initialize():
			get_viewport().arvr = true;
			Engine.target_fps = 80 # TODO: this is headset dependent (RiftS == 80)=> figure out how to get this info at runtime
			Engine.iterations_per_second = 80
			OS.vsync_enabled = false;
			print("  Success initializing Oculus Interface.");
			# C:/Users/henry/Appdata/Local/Android/Sdk/platform-tools/adb.exe logcat -s VrApi
		else:
			Tglobal.arvrinterface = null
				
	if enablevr and checkloadinterface("OpenVR"):
		print("found openvr, initializing")
		if Tglobal.arvrinterface.initialize():
			var viewport = get_viewport()
			viewport.arvr = true
			print("tttt", viewport.hdr, " ", viewport.keep_3d_linear)
			#viewport.hdr = false
			viewport.keep_3d_linear = true
			Engine.target_fps = 90
			Engine.iterations_per_second = 90
			OS.vsync_enabled = false;
			print("  Success initializing OpenVR Interface.");
		else:
			Tglobal.arvrinterface = null
				
	if enablevr and false and checkloadinterface("Native mobile"):
		print("found nativemobile, initializing")
		if Tglobal.arvrinterface.initialize():
			var viewport = get_viewport()
			viewport.arvr = true
			viewport.render_target_v_flip = true # <---- for your upside down screens
			viewport.transparent_bg = true       # <--- For the AR
			Tglobal.arvrinterface.k1 = 0.2          # Lens distortion constants
			Tglobal.arvrinterface.k2 = 0.23
	
	Tglobal.VRoperating = (Tglobal.arvrinterfacename != "none")
	if Tglobal.VRoperating:
		#$BodyObjects/Locomotion_WalkInPlace.initjogdetectionsystem(playerMe.get_node("HeadCam"))
		if Tglobal.arvrinterfacename == "OVRMobile":
			playerMe.initquesthandtrackingnow(ovr_hand_tracking)
			$WorldEnvironment/DirectionalLight.shadow_enabled = false
			$BodyObjects/PlayerDirections.initquesthandcontrollersignalconnections()
		else:
			playerMe.initnormalvrtrackingnow()
			$BodyObjects/PlayerDirections.initcontrollersignalconnections()
			
	else:
		playerMe.initkeyboardcontroltrackingnow()
		print("*** VR not working")
		
	print("*-*-*-*  requesting permissions: ", OS.request_permissions())
	# this relates to Android permissions: 	change_wifi_multicast_state, internet, 
	#										read_external_storage, write_external_storage, 
	#										capture_audio_output
	var perm = OS.get_granted_permissions()
	print("Granted permissions: ", perm)

	if false:
		#$SketchSystem.loadcentrelinefile("res://surveyscans/dukest1resurvey2009json.res")
		$SketchSystem.loadcentrelinefile("res://surveyscans/Ireby/Ireby2/Ireby2.json")
		$SketchSystem.updatecentrelinevisibility()
		$SketchSystem.changetubedxcsvizmode()
		$SketchSystem.updateworkingshell()
	elif true:
		$SketchSystem.loadsketchsystem("res://surveyscans/smallirebysave.res")
		#loadsketchsystem("res://surveyscans/ireby2save.res")
	else:
		pass
	playerMe.global_transform.origin.y += 5


func nextplayernetworkidinringskippingdoppelganger(deletedid):
	for i in range($Players.get_child_count()):
		var nextringplayer = $Players.get_child((playerMe.get_index()+1)%$Players.get_child_count())
		if deletedid == 0 or nextringplayer.networkID != deletedid:
			if nextringplayer.networkID != 0:
				return nextringplayer.networkID
	return 0
	
# May need to use Windows Defender Firewall -> Inboard rules -> New Rule and ports
# Also there's another setting change to allow pings
func _player_connected(id):
	print("_player_connected ", id)
	playerMe.set_name("NetworkedPlayer"+String(playerMe.networkID))
	var playerothername = "NetworkedPlayer"+String(id)
	if not $Players.has_node(playerothername):
		var playerOther = load("res://nodescenes/PlayerPuppet.tscn").instance()
		setnetworkidnamecolour(playerOther, id)
		playerOther.visible = false
		$Players.add_child(playerOther)
	if playerMe.networkID == 1:
		var sketchdatadict = $SketchSystem.sketchsystemtodict()
		$SketchSystem.rpc_id(id, "sketchsystemfromdict", sketchdatadict)
	playerMe.bouncetestnetworkID = nextplayernetworkidinringskippingdoppelganger(0)
	Tglobal.morethanoneplayer = $Players.get_child_count() >= 2
	playerMe.rpc("initplayerpuppet", (ovr_hand_tracking != null))
	$GuiSystem/GUIPanel3D/Viewport/GUI/Panel/Label.text = "player "+String(id)+" connected"
	
func _player_disconnected(id):
	print("_player_disconnected ", id)
	var playerothername = "NetworkedPlayer"+String(id)
	Tglobal.morethanoneplayer = $Players.get_child_count() >= 2
	var playerOther = $Players.get_node_or_null(playerothername)
	if playerOther != null:
		Tglobal.soundsystem.quicksound("PlayerDepart", playerOther.get_node("HeadCam").global_transform.origin)
		playerOther.queue_free()
	playerMe.bouncetestnetworkID = nextplayernetworkidinringskippingdoppelganger(id)
	$GuiSystem/GUIPanel3D/Viewport/GUI/Panel/Label.text = "player "+String(id)+" disconnected"
		
func _connected_to_server():
	print("_connected_to_server")
	var newnetworkID = get_tree().get_network_unique_id()
	if playerMe.networkID != newnetworkID:
		print("setting the newnetworkID: ", newnetworkID)
		setnetworkidnamecolour(playerMe, newnetworkID)
	$GuiSystem/GUIPanel3D/Viewport/GUI/Panel/Label.text = "connected as "+String(playerMe.networkID)

	print("SETTING connectiontoserveractive true now")
	Tglobal.connectiontoserveractive = true
	playerMe.rpc("initplayerpuppet", (ovr_hand_tracking != null))
		
	
func _process(_delta):
	if !perform_runtime_config:
		ovr_performance.set_clock_levels(1, 1)
		ovr_performance.set_extra_latency_mode(1)
		perform_runtime_config = true
		set_process(false)
				

func clearallprocessactivityforreload():
	$LabelGenerator.workingxcnode = null
	$LabelGenerator.remainingxcnodes.clear()
	$ImageSystem.fetcheddrawing = null
	$ImageSystem.paperdrawinglist.clear()

	if playerMe != null:
		var pointersystem = playerMe.get_node("pointersystem")
		pointersystem.clearactivetargetnode()  # clear all the objects before they are freed
		#pointersystem.clearpointertargetmaterial()
		pointersystem.clearpointertarget()
		pointersystem.setactivetargetwall(null)


