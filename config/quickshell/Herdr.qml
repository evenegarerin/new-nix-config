// waybar: custom/herdr — a single dot coloured by the most urgent agent.
BarText {
  text: HerdrService.text
  color: Theme.herdr[HerdrService.agentClass] !== undefined ? Theme.herdr[HerdrService.agentClass] : Theme.herdr["unknown"]
}
