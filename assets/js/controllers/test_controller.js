import { Controller } from "stimulus";

export default class extends Controller {
  // static targets = ["bums"]

  connect() {
    console.log("Stimulus connected...")
    // this.bumsTarget.textContent = "PAHAHAHAHAHAH"
  }
}