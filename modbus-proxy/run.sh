#!/usr/bin/with-contenv bashio

set +x

# Create main config
CONFIG_LOGLEVEL=$(bashio::config 'loglevel')

echo "Preparing to run modbus-proxy"
echo "Loglevel: $CONFIG_LOGLEVEL"

# Generate devices configuration
DEVICES_CONF=""
for device in $(bashio::config 'devices|keys'); do
    HOST=$(bashio::config "devices[${device}].upstreamhost")
    PORT=$(bashio::config "devices[${device}].upstreamport")
    LISTENPORT=$(bashio::config "devices[${device}].listenport")
    TIMEOUT=$(bashio::config "devices[${device}].timeout")
    CONNECTIONTIME=$(bashio::config "devices[${device}].connection_time")

    echo "Adding device: $HOST:$PORT (listening on $LISTENPORT)"

    DEVICES_CONF="${DEVICES_CONF}  - modbus:\n      url: ${HOST}:${PORT}\n      timeout: ${TIMEOUT}\n      connection_time: ${CONNECTIONTIME}\n    listen:\n      bind: 0:${LISTENPORT}\n"
done

# Strip trailing newline from DEVICES_CONF
DEVICES_CONF=$(echo -e "$DEVICES_CONF" | sed '$d')

# Use python to perform the replacement to handle multiple lines and special characters correctly
python3 -c "
import sys
content = open('./modbus.config.yaml').read()
devices_conf = '''$DEVICES_CONF'''.replace('\\\\n', '\n')
content = content.replace('# __DEVICES__', devices_conf)
content = content.replace('__LOGLEVEL__', '$CONFIG_LOGLEVEL')
with open('./modbus.config.yaml', 'w') as f:
    f.write(content)
"

echo "Generated Config"
cat ./modbus.config.yaml

if [ -f "./venv/bin/activate" ] ; then
    source ./venv/bin/activate
fi
modbus-proxy -c ./modbus.config.yaml