#!/bin/bash

wait_for_listener() {
	local port="$1"
	local attempts=0

	until (echo >/dev/tcp/127.0.0.1/"$port") 2>/dev/null; do
		attempts=$((attempts + 1))
		if (( attempts >= 60 )); then
			echo "Timed out waiting for port $port to open."
			return 1
		fi
		sleep 1
	done
}

make_port_public() {
	local port="$1"

	if [[ -z "${CODESPACE_NAME:-}" ]] || ! command -v gh >/dev/null 2>&1; then
		echo "Cannot make port $port public: this is not a GitHub Codespaces shell or gh is unavailable."
		return 1
	fi

	for _ in {1..60}; do
		if gh codespace ports -c "$CODESPACE_NAME" --json sourcePort --jq '.[].sourcePort' 2>/dev/null | grep -qx "$port"; then
			if gh codespace ports visibility "$port:public" -c "$CODESPACE_NAME"; then
				echo "Port $port is now public."
				return 0
			fi
			break
		fi
		sleep 1
	done

	echo "Port $port was not forwarded, so it was not made public."
	return 1
}

echo "Starting Velocity proxy..."
cd velocity
java -jar velocity-3.5.0-all.jar &
if wait_for_listener 25567; then
	make_port_public 25567
fi
cd ..

echo "Starting Limbo..."
cd limbo
java -jar server.jar &
wait_for_listener 25566
cd ..

echo "Starting Paper server..."
cd server
java -jar paper.jar </dev/tty &
paper_pid=$!
if wait_for_listener 25565; then
	make_port_public 25565
fi
wait "$paper_pid"

echo "------------------------------------------------------------------------------"
echo "You have stopped the server!"
echo "(origin: /stop or "ctrl + c", or server crashed either on startup or from in-game actions.)"
echo "(message origin: startup.sh)"
echo "Paper Server was stopped after starting so this message appeared."
echo "You can edit this message inside"
echo "bye!"
echo "------------------------------------------------------------------------------"
sleep 10
echo "Everything Successfully (Probably) Stopped. You May Use TERMINAL Commands Now."