extends Node2D

signal card_selected(card)

const COLLISION_MASK_CARD = 1

@export var fan_spacing := 60.0
@export var fan_angle := 8.0          # degrees between neighbouring cards
@export var fan_arc := 6.0            # how much the outer cards dip
@export var stack_offset := Vector2(1, -1)
@export var fan_duration := 0.35
@export var hover_lift := 30.0

var screen_size
var card_being_dragged
var is_hovered_over_card

var is_open := false
var cards: Array = []                 # filled by connect_card_signal
var base_positions := {}              # card -> layout position (without hover lift)
var layout_tween: Tween
var layout_queued := false
var interactive := true                # the game turns clicks off outside memory events


@export var right_margin := 100.0     # distance from the right edge to the deck's origin
@export var bottom_margin := 300    # distance from the bottom edge (origin is the card's bottom-center)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	position = Vector2(screen_size.x - right_margin, screen_size.y - bottom_margin)
	_queue_layout()

	# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#if card_being_dragged:
		#var mouse_pos = get_global_mouse_position()
		#card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), 
			#clamp(mouse_pos.y, 0, screen_size.y))

#func _input(event):
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		#if event.is_pressed():
			#var card = raycast_check_for_card()
			#if card:
				#start_drag(card)
				#
		#else:
			#finish_drag()

func _input(event):
	if not interactive:
		return
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.is_pressed():
		var card = raycast_check_for_card()
		if card == null:
			if is_open:
				toggle()              # clicked empty space: fold back up
		elif not is_open:
			toggle()                  # clicked the stack: fan out
		else:
			on_card_selected(card)    # clicked a card in the fan

func on_card_selected(card):
	card_selected.emit(card)

func remove_card(card) -> void:
	cards.erase(card)
	base_positions.erase(card)
	var tween := create_tween()
	tween.tween_property(card, "modulate:a", 0.0, fan_duration)
	tween.tween_callback(card.queue_free)
	_apply_layout(true)

func toggle() -> void:
	is_open = not is_open
	# clear any hover state so cards don't stay enlarged/lifted
	for card in cards:
		card.scale = Vector2(1, 1)
		card.z_index = 1
	is_hovered_over_card = false
	_apply_layout(true)

func _queue_layout() -> void:
	if layout_queued:
		return
	layout_queued = true
	call_deferred("_run_queued_layout")

func _run_queued_layout() -> void:
	layout_queued = false
	_apply_layout(false)

func _apply_layout(animate: bool) -> void:
	var n := cards.size()
	if n == 0:
		return

	if layout_tween and layout_tween.is_running():
		layout_tween.kill()
	if animate:
		layout_tween = create_tween().set_parallel(true)
		layout_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	for i in n:
		var card = cards[i]
		var t := i - (n - 1) / 2.0

		var target_pos: Vector2
		var target_rot: float
		if is_open:
			var k := (n - 1) - i                 # 0 for the top card, grows toward the left
			var arc_y := t * t * fan_arc
			var arc_y_top := ((n - 1) / 2.0) * ((n - 1) / 2.0) * fan_arc   # arc offset of the top card
			target_pos = Vector2(-k * fan_spacing, arc_y - arc_y_top)
			target_rot = deg_to_rad(t * fan_angle)
		else:
			target_pos = stack_offset * i
			target_rot = 0.0

		base_positions[card] = target_pos

		if animate:
			layout_tween.tween_property(card, "position", target_pos, fan_duration)
			layout_tween.tween_property(card, "rotation", target_rot, fan_duration)
		else:
			card.position = target_pos
			card.rotation = target_rot

#func start_drag(card):
	#card.get_parent().move_child(card, -1)
	#card_being_dragged = card
	#card.scale = Vector2(1.0, 1.0)
	#
#func finish_drag():
	#if card_being_dragged != null:
		#card_being_dragged.scale = Vector2(1.05, 1.05) 
	#card_being_dragged = null

#func connect_card_signal(card):
	#card.connect("hovered", on_hovered_over_card)
	#card.connect("hovered_off", on_hovered_off_card)
#
#func on_hovered_over_card(card):
	#if !is_hovered_over_card:
		#is_hovered_over_card = true;
		#highlight_card(card, true)
	#
	#
#
#func on_hovered_off_card(card):
	##if !card_being_dragged:
	##is_hovered_over_card = false
	#highlight_card(card, false)
	#var new_card_hovered = raycast_check_for_card()
	#if new_card_hovered:
		#highlight_card(new_card_hovered, true)
		#is_hovered_over_card = true
	#else:
		#is_hovered_over_card = false 
	#
	#
#
#func highlight_card(card, hovered):
	#if hovered:
		#card.scale = Vector2(1.05, 1.05)
		#card.z_index = 2
	#else:
		#card.scale = Vector2(1, 1)
		#card.z_index = 1
##
#func raycast_check_for_card():
	#var space_state = get_world_2d().direct_space_state
	#var parameters = PhysicsPointQueryParameters2D.new()
	#parameters.position = get_global_mouse_position()
	#parameters.collide_with_areas = true
	#parameters.collision_mask = COLLISION_MASK_CARD
	#var result = space_state.intersect_point(parameters)
	#if result.size() > 0:
		##return result[0].collider.get_parent()
		#return get_card_with_highest_z_index(result)
	#return null
#
#func get_card_with_highest_z_index(cards):
	#var highest_z_card = cards[0].collider.get_parent()
	#var highest_z_index = highest_z_card.z_index
	#for i in range(1, cards.size()):
		#var current_card = cards[i].collider.get_parent()
		#if current_card.z_index > highest_z_index:
			#highest_z_card = current_card
			#highest_z_index = current_card.z_index
	#return highest_z_card

func connect_card_signal(card):
	if not cards.has(card):
		cards.append(card)
		_queue_layout()
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)

func on_hovered_over_card(card):
	if !is_open:
		return                        # no hover effect while folded
	if !is_hovered_over_card:
		is_hovered_over_card = true
		highlight_card(card, true)

func on_hovered_off_card(card):
	highlight_card(card, false)
	if !is_open:
		is_hovered_over_card = false
		return
	var new_card_hovered = raycast_check_for_card()
	if new_card_hovered:
		highlight_card(new_card_hovered, true)
		is_hovered_over_card = true
	else:
		is_hovered_over_card = false

func highlight_card(card, hovered):
	var base: Vector2 = base_positions.get(card, card.position)
	var target_pos := base
	if hovered:
		card.scale = Vector2(1.05, 1.05)
		card.z_index = 2
		# lift along the card's own "up" so it follows the fan rotation
		target_pos = base + Vector2.UP.rotated(card.rotation) * hover_lift
	else:
		card.scale = Vector2(1, 1)
		card.z_index = 1

	if is_open and not (layout_tween and layout_tween.is_running()):
		create_tween().tween_property(card, "position", target_pos, 0.1)

func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return get_card_with_highest_z_index(result)
	return null

func get_card_with_highest_z_index(hits):
	var best = hits[0].collider.get_parent()
	for i in range(1, hits.size()):
		var current = hits[i].collider.get_parent()
		# higher z_index wins; on a tie, the card drawn later (lower in tree) wins
		if current.z_index > best.z_index \
				or (current.z_index == best.z_index and current.get_index() > best.get_index()):
			best = current
	return best
