defmodule Metex.Worker do
  
  def temperature_of(location) do
    result = url_for(location) |> HTTPoison.get |> parse_response
    case result do
      {:ok, temp} ->
        IO.inspect "#{location}: #{temp}°C"
      :error ->
        "#{location} not found"
    end
  end

  defp url_for(location) do
    location = URI.encode(location)
    "http://api.openweathermap.org/data/2.5/weather?q=#{location}&appid=#{apikey}"
  end
  
  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body |> JSON.decode! |> compute_temperature
  end

  defp parse_response(_) do
    :error
  end

  defp compute_temperature(json) do
    try do
      temp = (json["main"]["temp"] - 273.15) |> Float.round(1)
      {:ok, temp}
    rescue
      _ -> :error
    end
  end

  defp apikey do
    "f768e77724d4bd4be2c6fa6eed4b96b3"
  end

  def loop do
     receive  do
      {sender_pid, location} ->
        send(sender_pid, temperature_of(location))
    _ -> 
      IO.puts "don't know how to send response of this.."
    end
    loop
  end

  def process_ping do
    receive do
      {sender_pid, msg} ->
        case String.upcase(msg) do
          "PING" -> send(sender_pid, "PONG")
          "PONG" -> send(sender_pid, "PING")
          _ -> send(sender_pid, "Wrong msg bitch..")
        end
      _ ->
        IO.puts "wrong msg"
    end
    process_ping
  end

  def calling_func do
    process_pid = 
      spawn(Metex.Worker, :process_ping, [])
      send process_pid, {self, "PING"}
  end
end
