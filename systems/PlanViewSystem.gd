extends Spatial

var planviewactive = false
var drawingtype = DRAWING_TYPE.DT_PLANVIEW

func _ready():
	$RealPlanCamera.set_as_toplevel(true)

	#$Viewport/GUI/Panel/ButtonLoad.connect("pressed", self, "_on_buttonload_pressed")
	#$Viewport/GUI/Panel/ButtonSave.connect("pressed", self, "_on_buttonsave_pressed")




func toggleplanviewactive():
	planviewactive = not planviewactive
	$PlanView/ProjectionScreen/ImageFrame.mesh.surface_get_material(0).emission_enabled = planviewactive

func setplanviewvisible(planviewvisible, guidpaneltransform, guidpanelsize):
	if planviewvisible:
		var paneltrans = $PlanView.global_transform
		paneltrans.origin = guidpaneltransform.origin + guidpaneltransform.basis.y*(guidpanelsize.y/2) + Vector3(0,$PlanView/ProjectionScreen/ImageFrame.mesh.size.y/2,0)
		var eyepos = get_node("/root/Spatial").playerMe.get_node("HeadCam").global_transform.origin
		paneltrans = paneltrans.looking_at(eyepos + 2*(paneltrans.origin-eyepos), Vector3(0, 1, 0))
		$PlanView.global_transform = paneltrans
		visible = true
		$PlanView/CollisionShape.disabled = false
	else:
		visible = false	
		$PlanView/CollisionShape.disabled = true

	
func processplanviewsliding(joypos, gripbuttonheld, delta):
	var planviewsystem = self
	var plancamera = planviewsystem.get_node("PlanView/Viewport/PlanGUI/Camera")
	if joypos.length() > 0.1 and not gripbuttonheld:
		plancamera.translation += Vector3(joypos.x, 0, -joypos.y)*plancamera.size/2*delta

func camerascalechange(sca):
	$PlanView/Viewport/Camera.size *= sca
	$RealPlanCamera/RealCameraBox.scale = Vector3($PlanView/Viewport/PlanGUI/Camera.size, 1.0, $PlanView/Viewport/PlanGUI/Camera.size)
	updatecentrelinesizes()
	
func cameraresetcentre(headcam):
	$PlanView/Viewport/PlanGUI/Camera.translation = Vector3(headcam.global_transform.origin.x, $PlanView/Viewport/PlanGUI/Camera.translation.y, headcam.global_transform.origin.z)

func checkplanviewinfront(handrightcontroller):
	var planviewsystem = self
	var collider_transform = planviewsystem.get_node("PlanView").global_transform
	return collider_transform.xform_inv(handrightcontroller.global_transform.origin).z > 0

var viewport_mousedown = false
func processplanviewpointing(raycastcollisionpoint, controller_trigger):
	var planviewsystem = self
	var plancamera = planviewsystem.get_node("PlanView/Viewport/PlanGUI/Camera")
	var collider_transform = planviewsystem.get_node("PlanView").global_transform
	var shape_size = planviewsystem.get_node("PlanView/CollisionShape").shape.extents * 2
	var collider_scale = collider_transform.basis.get_scale()
	var local_point = collider_transform.xform_inv(raycastcollisionpoint)
	local_point /= (collider_scale * collider_scale)
	local_point /= shape_size
	local_point += Vector3(0.5, -0.5, 0) # X is about 0 to 1, Y is about 0 to -1.
	var viewport_point = Vector2(local_point.x, -local_point.y) * $PlanView/Viewport.size

	var rectrel = viewport_point - $PlanView/Viewport/PlanGUI/PlanViewControls.rect_position
	if rectrel.x > 0 and rectrel.y > 0 and rectrel.x < $PlanView/Viewport/PlanGUI/PlanViewControls.rect_size.x and rectrel.y < $PlanView/Viewport/PlanGUI/PlanViewControls.rect_size.y:
		var event = InputEventMouseMotion.new()
		event.position = viewport_point
		$PlanView/Viewport.input(event)
		if controller_trigger != viewport_mousedown:
			viewport_mousedown = controller_trigger
			event = InputEventMouseButton.new()
			event.pressed = viewport_mousedown
			event.button_index = BUTTON_LEFT
			event.position = viewport_point
			print("vvvv viewport_point ", viewport_point)
			$PlanView/Viewport.input(event)
	else:
		var laspt = plancamera.project_position(viewport_point, 0)
		planviewsystem.get_node("RealPlanCamera/LaserScope").global_transform.origin = laspt
		planviewsystem.get_node("RealPlanCamera/LaserScope").visible = true
		planviewsystem.get_node("RealPlanCamera/LaserScope/LaserOrient/RayCast").force_raycast_update()


func Dguipanelreleasemouse():
	if viewport_mousedown:
		var event = InputEventMouseButton.new()
		event.button_index = 1
		#event.position = viewport_point
		$Viewport.input(event)
		viewport_mousedown = false

func updatecentrelinesizes():
	var sca = $PlanView/Viewport/PlanGUI/Camera.size/70.0*2.5 if Tglobal.centrelineonly else 1.0
	for xcdrawing in get_tree().get_nodes_in_group("gpcentrelinegeo"):
		for xcn in xcdrawing.get_node("XCnodes").get_children():
			xcn.get_node("Quad").get_surface_material(0).set_shader_param("vertex_scale", sca)
			xcn.get_node("CollisionShape").scale = Vector3(sca*2, sca*2, sca*2)
		xcdrawing.linewidth = 0.035*sca
		xcdrawing.updatexcpaths()



