defmodule Chat.Server do
	use GenServer

	def start_link(_) do
		GenServer.start_link(__MODULE__, nil, name: __MODULE__)
	end 

	def new_client(socket) do 
		GenServer.cast(__MODULE__, {:new, socket})
	end

	def change_name(socket, new_name) do
		GenServer.call(__MODULE__, {:chname, socket, new_name})
	end

	def msg(name) do
		GenServer.call(__MODULE__, {:msg, name})
	end

	def get_nick(socket) do
		GenServer.call(__MODULE__, {:get_nick, socket})
	end

	def rm_nick(socket) do
		GenServer.cast(__MODULE__, {:rm_nick, socket})
	end

	def init(_) do
		{:ok, %{}}
	end

	def handle_cast({:new, socket}, map) do
		rnum = :rand.uniform(50)
		map = Map.put(map, rnum, socket)
		{:noreply, map}
	end

	def handle_cast({:rm_nick, socket}, map) do
		key = map |> Enum.find(fn {_key, val} -> val == socket end) |> elem(0)
		map = Map.delete(map, key)
		{:noreply, map}
	end

	def handle_call({:chname, socket, new_name}, _from, map) do
		IO.puts("in hdnl_call :chname")
		if (Map.has_key?(map, new_name)) do
			{:reply, :name_in_use, map}
		else
			key = map |> Enum.find(fn {_key, val} -> val == socket end) |> elem(0)
			IO.puts(key)
			map = Map.put(map, new_name, socket)
			map = Map.delete(map, key)
			IO.puts(new_name)
			{:reply, new_name, map}
		end
	end

	def handle_call({:get_nick, socket}, _from, map) do
			key = map |> Enum.find(fn {_key, val} -> val == socket end) |> elem(0)
			{:reply, key, map}
	end

	def handle_call({:msg, name}, _from, map) do
		# sockets = []
		if (name == ";") do
			keys = Map.keys(map)
			sockets = getSockets(keys, map, [])
			{:reply, sockets, map}
		else
			IO.puts("hc_:msg namecheck")
			IO.puts(name)
			names = String.split(name, ",")
			sockets = getSockets(names, map, [])
			{:reply, sockets, map}
		end
	end

	def getSockets(names, map, sockets) when length(names) > 0 do
		[head | tail] = names
		# IO.puts(head)
		socket = 
			case Map.fetch(map, head) do
				{:ok, socket} -> socket
				:error -> :error 
			end
		new_sockets = [socket | sockets]
		getSockets(tail, map, new_sockets)
	end

	def getSockets(_names, _map, sockets) do
		sockets
	end

end
