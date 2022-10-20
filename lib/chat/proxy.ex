defmodule Chat.Proxy do
  use GenServer
  alias Chat.Server

  def start_link(port) do
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  def init(port) do
    {:ok, socket} = :gen_tcp.listen(port,
      [:binary, {:active, true}, {:reuseaddr, true}])
    spawn(fn -> accept_client(socket) end)
    {:ok, port}
  end

  def accept_client(socket) do
    IO.puts("in accept_client")
    {:ok, connected_socket} = :gen_tcp.accept(socket)
    IO.puts("connected")
    Server.new_client(connected_socket)
    spawn(fn -> accept_client(socket) end)
    loop(connected_socket)
  end

  def loop(socket) do
    receive do
      {:tcp, ^socket, data} ->
        data = data |> String.replace("\r", "") |> String.replace("\n", "")
        IO.puts(data)
        if (data == "eof") do
          Server.rm_nick(socket)
        else
          handle_data(socket, data)
        end
        loop(socket)
      {:tcp_closed, socket} ->
        :gen_tcp.close(socket)
    end
  end

  def handle_data(socket, data) do
    parts = String.split(data, "#")
    cmd = Enum.at(parts, 0)
    IO.puts("parts: #{cmd}")
    if (cmd == "nick") do
      IO.puts("in nickif")
      handle_nick(socket, Enum.at(parts, 1))
    else
      IO.puts("in msgif")
      handle_mssg(Enum.at(parts, 1), Enum.at(parts, 2), socket)
    end
  end

  def handle_mssg(names, msg, socket) do
    IO.puts("in h_msg")
    IO.puts(names)
    msg_sockets = Server.msg(names)
    for i <- msg_sockets do
      if (i != socket) do
        if (i == :error) do
          :gen_tcp.send(socket, "recipient not online\n")
        else
          name = Server.get_nick(socket);
          msg_out = "#{name}~>#{msg}\n"
          :gen_tcp.send(i, msg_out)
        end
      end
    end
  end

  def handle_nick(socket, name) do
    IO.puts("in h_nick")
    name = Server.change_name(socket, name)
    IO.puts("back")
    if (name == :name_in_use) do
      :gen_tcp.send(socket, "name is already in use\n")
    else
      out = "#{name} is now your name\n"
      :gen_tcp.send(socket, out)
    end
  end
end