#!/bin/bash

/opt/server.data/bin/jennifer_data.sh start && \
/opt/server.view/bin/jennifer_view.sh start && \
echo "Jennifer Server start"

sleep 10

/bin/bash