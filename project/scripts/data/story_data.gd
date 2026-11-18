class_name StoryData
extends Resource
## The universe's story: the one-time Introduction and the codex Timeline.
##
## Plain English: the Introduction is shown once, after TAP TO START, on one
## screen (tap to continue). The Timeline is an optional codex page.
## Edit res://data/story/story.tres to change the words.

@export var title := "ORBSPIRE"
@export_multiline var introduction: String = ""
## Each entry: "Year 82 · First Splice" on one line, then the text.
@export var timeline_titles: Array[String] = []
@export var timeline_texts: Array[String] = []
