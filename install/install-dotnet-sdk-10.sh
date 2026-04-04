#!/bin/bash

export DOTNET_CLI_TELEMETRY_OPTOUT=1
echo "export DOTNET_CLI_TELEMETRY_OPTOUT=1" >> /etc/profile.d/dotnet-optout.sh

# rm -rf /usr/lib/dotnet

wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --channel 10.0 --install-dir /usr/lib/dotnet

echo '' > /etc/profile.d/dotnet-paths.sh
echo 'export DOTNET_ROOT=/usr/lib/dotnet' >> /etc/profile.d/dotnet-paths.sh
echo 'export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools' >> /etc/profile.d/dotnet-paths.sh

ln -s /usr/lib/dotnet/dotnet /usr/bin/dotnet
