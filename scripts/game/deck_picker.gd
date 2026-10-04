extends CanvasLayer
## Lets the player pick a memory from the card deck. Drives card_manager: brings the deck
## forward, fans it out, and reports which offered card was clicked.

signal picked(id: String)

# Card node names in card_table.tscn -> ids used by GameState and the controller.
const CARD_IDS = {
	"Death": "death",
	"TheFool": "fool",
	"Justice": "justice",
	"Strength": "strength",
	"TheHermit": "hermit",
	"TheHangedMan": "hanged_man",
	"WheelOfFortune": "wheel",
}
const MOVE_TIME = 0.4
const DIMMED = Color(0.3, 0.3, 0.38)

@export var deck: Node2D
## Centre of the fan while the player is choosing.
@export var pick_centre := Vector2(576, 370)
## Wider than the deck's own spacing so every offered card can be seen and clicked.
@export var pick_spacing := 115.0

var _home: Vector2
var _offered: Array[String] = []
var _move: Tween
@onready var _heading: Label = $Heading

func _ready() -> void:
	_heading.hide()
	_home = deck.position
	deck.interactive = false
	deck.card_selected.connect(_on_card_selected)
	GameState.memory_lost.connect(_on_memory_lost)

func is_picking() -> bool:
	return deck.interactive

## ids are memory ids (and "death"). Cards that are not offered stay in the fan, dimmed.
func present(ids: Array[String]) -> void:
	_offered = ids
	for card in deck.cards:
		card.modulate = Color.WHITE if _offered.has(CARD_IDS.get(card.name, "")) else DIMMED
	_heading.show()
	# The fan grows leftwards from the deck's origin, so the origin sits right of centre.
	deck.fan_spacing = pick_spacing
	_move_deck(pick_centre + Vector2((deck.cards.size() - 1) * pick_spacing / 2.0, 0))
	deck.interactive = true
	if not deck.is_open:
		deck.toggle()

func _on_card_selected(card: Node) -> void:
	var id: String = CARD_IDS.get(card.name, "")
	if not _offered.has(id):
		return
	deck.interactive = false
	if deck.is_open:
		deck.toggle()
	for other in deck.cards:
		other.modulate = Color.WHITE
	_heading.hide()
	_move_deck(_home)
	picked.emit(id)

func _on_memory_lost(memory_id: String) -> void:
	for card in deck.cards:
		if CARD_IDS.get(card.name, "") == memory_id:
			deck.remove_card(card)
			return

func _move_deck(target: Vector2) -> void:
	if _move:
		_move.kill()
	_move = create_tween()
	_move.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_move.tween_property(deck, "position", target, MOVE_TIME)
