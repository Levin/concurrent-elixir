defmodule PageConsumer do
  
  use GenStage
  require Logger

  def start_link(event) do

    Logger.debug("PageConsumer got a new event #{inspect event}")
    Task.start_link(fn _ -> Scraper.work() end)

    #GenStage.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  # unused for now

  def init(initial_state) do
    Logger.info("PageConsumer started")
    opts = [{PageProducer, min_demand: 0, max_demand: 2}]
    {:consumer, initial_state, subscribe_to: opts}
  end

  def handle_events(events, _from, state) do
    Logger.debug("PageConsumer received #{inspect events}")
    Enum.each(events, fn _page -> Scraper.work() end)
    {:noreply, [], state}
  end

end
