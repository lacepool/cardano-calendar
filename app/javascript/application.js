// Entry point for the build script in your package.json
import { Turbo } from "@hotwired/turbo-rails"
Turbo.session.drive = true

import { Application } from "@hotwired/stimulus"
import PopperController from "./controllers/popper_controller"

window.Stimulus = Application.start()
Stimulus.debug = true

Stimulus.register("popper", PopperController)

import "./theme";
