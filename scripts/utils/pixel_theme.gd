## Pixel-style theme for Godot 4 idle game
## Creates a retro pixel art aesthetic for all UI elements

class_name RetroTheme
extends RefCounted

# Pixel art color palette
const COLOR_BG := Color("#1a1a2e")           # Deep blue-black
const COLOR_PANEL := Color("#16213e")         # Dark blue
const COLOR_BORDER := Color("#d4af37")        # Gold (accent - matches landlord theme)
const COLOR_SECONDARY := Color("#0f3460")     # Medium blue
const COLOR_TEXT := Color("#eaeaea")          # Off-white
const COLOR_TEXT_DIM := Color("#8b8b8b")      # Dimmed text
const COLOR_BUTTON := Color("#0f3460")        # Button background
const COLOR_BUTTON_HOVER := Color("#1a4a7a") # Button hover
const COLOR_BUTTON_PRESSED := Color("#d4af37") # Button pressed
const COLOR_SEPARATOR := Color("#d4af37")     # Separator color

# Border width for pixel look
const BORDER_WIDTH := 2

# Load Chinese font for web export (Godot 4 uses FontFile instead of DynamicFont)
static func _get_chinese_font() -> FontFile:
	var chinese := load("res://assets/NotoSansSC.otf") as FontFile
	var emoji := load("res://assets/NotoEmoji.ttf") as FontFile
	
	# Create FontVariation to chain fallbacks (Chinese -> Emoji)
	var variation := FontVariation.new()
	variation.base_font = chinese
	if emoji:
		variation.fallbacks = [emoji]
	
	# Return the base font with variation settings
	# Note: For full fallback support, use variation as default font
	return chinese

# Get font with emoji fallback for emoji support
static func _get_font_with_emoji() -> Font:
	var chinese := load("res://assets/NotoSansSC.otf") as FontFile
	var emoji := load("res://assets/NotoEmoji.ttf") as FontFile
	
	var variation := FontVariation.new()
	variation.base_font = chinese
	if emoji:
		variation.fallbacks = [emoji]
	return variation

# Get the configured Theme object
static func get_theme() -> Theme:
	var theme := Theme.new()
	
	# Use font with emoji fallback
	var font_with_emoji = _get_font_with_emoji()
	ThemeDB.set_fallback_font(font_with_emoji)
	theme.default_font = font_with_emoji
	
	# PanelContainer styles
	theme.set_color("panel_color", "PanelContainer", COLOR_PANEL)
	theme.set_constant("panel_separation", "PanelContainer", 0)
	
	# Create StyleBoxFlat for PanelContainer
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_PANEL
	panel_style.border_color = COLOR_BORDER
	panel_style.border_width_left = BORDER_WIDTH
	panel_style.border_width_top = BORDER_WIDTH
	panel_style.border_width_right = BORDER_WIDTH
	panel_style.border_width_bottom = BORDER_WIDTH
	panel_style.corner_radius_top_left = 0
	panel_style.corner_radius_top_right = 0
	panel_style.corner_radius_bottom_right = 0
	panel_style.corner_radius_bottom_left = 0
	theme.set_stylebox("panel", "PanelContainer", panel_style)
	
	# Create alternate panel style (darker)
	var panel_dark_style := StyleBoxFlat.new()
	panel_dark_style.bg_color = COLOR_BG
	panel_dark_style.border_color = COLOR_BORDER
	panel_dark_style.border_width_left = BORDER_WIDTH
	panel_dark_style.border_width_top = BORDER_WIDTH
	panel_dark_style.border_width_right = BORDER_WIDTH
	panel_dark_style.border_width_bottom = BORDER_WIDTH
	panel_dark_style.corner_radius_top_left = 0
	panel_dark_style.corner_radius_top_right = 0
	panel_dark_style.corner_radius_bottom_right = 0
	panel_dark_style.corner_radius_bottom_left = 0
	theme.set_stylebox("panel", "Panel", panel_dark_style)
	
	# Button styles
	var button_normal := StyleBoxFlat.new()
	button_normal.bg_color = COLOR_BUTTON
	button_normal.border_color = COLOR_BORDER
	button_normal.border_width_left = BORDER_WIDTH
	button_normal.border_width_top = BORDER_WIDTH
	button_normal.border_width_right = BORDER_WIDTH
	button_normal.border_width_bottom = BORDER_WIDTH
	button_normal.corner_radius_top_left = 0
	button_normal.corner_radius_top_right = 0
	button_normal.corner_radius_bottom_right = 0
	button_normal.corner_radius_bottom_left = 0
	theme.set_stylebox("normal", "Button", button_normal)
	
	var button_hover := StyleBoxFlat.new()
	button_hover.bg_color = COLOR_BUTTON_HOVER
	button_hover.border_color = COLOR_BORDER
	button_hover.border_width_left = BORDER_WIDTH
	button_hover.border_width_top = BORDER_WIDTH
	button_hover.border_width_right = BORDER_WIDTH
	button_hover.border_width_bottom = BORDER_WIDTH
	button_hover.corner_radius_top_left = 0
	button_hover.corner_radius_top_right = 0
	button_hover.corner_radius_bottom_right = 0
	button_hover.corner_radius_bottom_left = 0
	theme.set_stylebox("hover", "Button", button_hover)
	
	var button_pressed := StyleBoxFlat.new()
	button_pressed.bg_color = COLOR_BUTTON_PRESSED
	button_pressed.border_color = COLOR_TEXT
	button_pressed.border_width_left = BORDER_WIDTH
	button_pressed.border_width_top = BORDER_WIDTH
	button_pressed.border_width_right = BORDER_WIDTH
	button_pressed.border_width_bottom = BORDER_WIDTH
	button_pressed.corner_radius_top_left = 0
	button_pressed.corner_radius_top_right = 0
	button_pressed.corner_radius_bottom_right = 0
	button_pressed.corner_radius_bottom_left = 0
	theme.set_stylebox("pressed", "Button", button_pressed)
	
	var button_disabled := StyleBoxFlat.new()
	button_disabled.bg_color = COLOR_SECONDARY
	button_disabled.border_color = COLOR_TEXT_DIM
	button_disabled.border_width_left = BORDER_WIDTH
	button_disabled.border_width_top = BORDER_WIDTH
	button_disabled.border_width_right = BORDER_WIDTH
	button_disabled.border_width_bottom = BORDER_WIDTH
	button_disabled.corner_radius_top_left = 0
	button_disabled.corner_radius_top_right = 0
	button_disabled.corner_radius_bottom_right = 0
	button_disabled.corner_radius_bottom_left = 0
	theme.set_stylebox("disabled", "Button", button_disabled)
	
	# Button font colors
	theme.set_color("font_color", "Button", COLOR_TEXT)
	theme.set_color("font_hover_color", "Button", COLOR_TEXT)
	theme.set_color("font_pressed_color", "Button", COLOR_BG)
	theme.set_color("font_disabled_color", "Button", COLOR_TEXT_DIM)
	
	# Label styles
	theme.set_color("font_color", "Label", COLOR_TEXT)
	theme.set_color("font_color_shadow", "Label", Color(0, 0, 0, 0.5))
	theme.set_constant("shadow_offset_x", "Label", 2)
	theme.set_constant("shadow_offset_y", "Label", 2)
	
	# Header label (large, prominent)
	theme.set_color("font_color", "LabelLarge", COLOR_TEXT)
	theme.set_constant("line_spacing", "Label", 4)
	
	# HSeparator style
	var hsep_style := StyleBoxFlat.new()
	hsep_style.bg_color = Color(0, 0, 0, 0)
	hsep_style.border_color = COLOR_SEPARATOR
	hsep_style.border_width_bottom = BORDER_WIDTH
	theme.set_stylebox("separator", "HSeparator", hsep_style)
	theme.set_color("separator_color", "HSeparator", COLOR_SEPARATOR)
	theme.set_constant("separation", "HSeparator", 8)
	
	# VSeparator style
	var vsep_style := StyleBoxFlat.new()
	vsep_style.bg_color = Color(0, 0, 0, 0)
	vsep_style.border_color = COLOR_SEPARATOR
	vsep_style.border_width_right = BORDER_WIDTH
	theme.set_stylebox("separator", "VSeparator", vsep_style)
	theme.set_color("separator_color", "VSeparator", COLOR_SEPARATOR)
	
	# ScrollBar styles
	var scrollbar_style := StyleBoxFlat.new()
	scrollbar_style.bg_color = COLOR_BG
	theme.set_stylebox("scroll", "ScrollBar", scrollbar_style)
	
	# ProgressBar style
	var progress_style := StyleBoxFlat.new()
	progress_style.bg_color = COLOR_SECONDARY
	progress_style.border_color = COLOR_BORDER
	progress_style.border_width_left = BORDER_WIDTH
	progress_style.border_width_top = BORDER_WIDTH
	progress_style.border_width_right = BORDER_WIDTH
	progress_style.border_width_bottom = BORDER_WIDTH
	progress_style.corner_radius_top_left = 0
	progress_style.corner_radius_top_right = 0
	progress_style.corner_radius_bottom_right = 0
	progress_style.corner_radius_bottom_left = 0
	theme.set_stylebox("background", "ProgressBar", progress_style)
	
	var progress_fill := StyleBoxFlat.new()
	progress_fill.bg_color = COLOR_BORDER
	progress_fill.border_color = COLOR_BORDER
	progress_fill.corner_radius_top_left = 0
	progress_fill.corner_radius_top_right = 0
	progress_fill.corner_radius_bottom_right = 0
	progress_fill.corner_radius_bottom_left = 0
	theme.set_stylebox("fill", "ProgressBar", progress_fill)
	
	# CheckButton style
	theme.set_color("font_color", "CheckButton", COLOR_TEXT)
	theme.set_color("font_hover_color", "CheckButton", COLOR_TEXT)
	
	# Set window colors for any popups
	theme.set_color("title_color", "Window", COLOR_BORDER)
	theme.set_color("font_color", "Window", COLOR_TEXT)
	
	return theme


# Get pixel-style StyleBoxFlat for custom use
static func create_panel_style(bg_color: Color = COLOR_PANEL, border_color: Color = COLOR_BORDER, 
							   border_width: int = BORDER_WIDTH) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	return style


# Get button style for custom use
static func create_button_style(bg_color: Color = COLOR_BUTTON, border_color: Color = COLOR_BORDER) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = BORDER_WIDTH
	style.border_width_top = BORDER_WIDTH
	style.border_width_right = BORDER_WIDTH
	style.border_width_bottom = BORDER_WIDTH
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_right = 0
	style.corner_radius_bottom_left = 0
	return style


# Get a pixel-style border for decorations
static func create_pixel_border(color: Color = COLOR_BORDER, width: int = BORDER_WIDTH) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = color
	style.border_width_left = width
	style.border_width_top = width
	style.border_width_right = width
	style.border_width_bottom = width
	return style


# Building colors for city view
const BUILDING_COLORS := {
	"apartment": Color("#4a90a4"),      # Teal blue
	"house": Color("#7cb342"),           # Green
	"shop": Color("#ffb300"),            # Amber
	"office": Color("#5c6bc0"),          # Indigo
	"factory": Color("#78909c"),         # Gray blue
	"warehouse": Color("#8d6e63"),        # Brown
	"hotel": Color("#ec407a"),           # Pink
	"skyscraper": Color("#26c6da"),      # Cyan
}

# Get building color by type
static func get_building_color(building_type: String) -> Color:
	return BUILDING_COLORS.get(building_type, COLOR_SECONDARY)
