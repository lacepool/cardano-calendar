// Entry point for the build script in your package.json
import { Turbo } from "@hotwired/turbo-rails"
Turbo.session.drive = true

import { Application } from "@hotwired/stimulus"
import PopperController from "./controllers/popper_controller"
import EventsController from "./controllers/events_controller"
import FiltersController from "./controllers/filters_controller"

import Clipboard from 'stimulus-clipboard'

window.Stimulus = Application.start()
Stimulus.debug = false

Stimulus.register("popper", PopperController)
Stimulus.register("events", EventsController)
Stimulus.register('clipboard', Clipboard)
Stimulus.register('filters', FiltersController)

import "./theme";
import "./maintain_scroll_positions"
import "./wallet_connect"
