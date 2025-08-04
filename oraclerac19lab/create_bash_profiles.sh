#!/bin/bash

# Script to manually create bash profiles for Oracle RAC users
# Usage: ./create_bash_profiles.sh [node_number]

set -e

# Determine node number
NODE_NUM=${1:-"auto"}

if [[ "$NODE_NUM" == "auto" ]]; then
    HOSTNAME=$(hostname)
    if [[ "$HOSTNAME" == *"node01"* ]]; then
        NODE_NUM="1"
        ASM_SID="+ASM1"
    elif [[ "$HOSTNAME" == *"node02"* ]]; then
        NODE_NUM="2"
        ASM_SID="+ASM2"
    else
        echo "Cannot determine node number from hostname: $HOSTNAME"
        echo "Usage: $0 [1|2]"
        exit 1
    fi
else
    ASM_SID="+ASM${NODE_NUM}"
fi

echo "Creating bash profiles for Oracle RAC Node $NODE_NUM"
echo "ASM SID will be set to: $ASM_SID"

# Ensure directories exist
echo "Creating user home directories..."
mkdir -p /services/oracle/gridhome
mkdir -p /services/oracle/orahome

# Create grid user .bash_profile
echo "Creating .bash_profile for grid user..."
cat > /services/oracle/gridhome/.bash_profile << EOF
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# User specific environment and startup programs

# Oracle Grid Infrastructure Environment for Node $NODE_NUM
export ORACLE_BASE=/services/oracle/grid/gridbase
export ORACLE_HOME=/services/oracle/grid/19.3/grid_home
export ORACLE_SID=$ASM_SID
export PATH=\$ORACLE_HOME/bin:\$PATH
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:\$LD_LIBRARY_PATH

# Grid Infrastructure specific
export GRID_HOME=\$ORACLE_HOME
export ASM_HOME=\$ORACLE_HOME

umask 022
EOF

# Create oracle user .bash_profile
echo "Creating .bash_profile for oracle user..."
cat > /services/oracle/orahome/.bash_profile << EOF
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# User specific environment and startup programs

# Oracle Database Environment for Node $NODE_NUM
export ORACLE_BASE=/services/oracle
export ORACLE_HOME=/services/oracle/db/19.3/db_home
export ORACLE_SID=rac${NODE_NUM}
export PATH=\$ORACLE_HOME/bin:\$PATH
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:\$LD_LIBRARY_PATH

# Oracle specific
export TNS_ADMIN=\$ORACLE_HOME/network/admin
export ORA_NLS11=\$ORACLE_HOME/nls/data

umask 022
EOF

# Set correct ownership and permissions
echo "Setting ownership and permissions..."
chown grid:oinstall /services/oracle/gridhome/.bash_profile
chown oracle:oinstall /services/oracle/orahome/.bash_profile

chmod 644 /services/oracle/gridhome/.bash_profile
chmod 644 /services/oracle/orahome/.bash_profile

# Set directory ownership
chown -R grid:oinstall /services/oracle/gridhome
chown -R oracle:oinstall /services/oracle/orahome

echo ""
echo "✅ Bash profiles created successfully!"
echo ""
echo "Files created:"
echo "  - /services/oracle/gridhome/.bash_profile (grid user, $ASM_SID)"
echo "  - /services/oracle/orahome/.bash_profile (oracle user, rac${NODE_NUM})"
echo ""
echo "To test the grid user environment:"
echo "  su - grid"
echo "  source ~/.bash_profile"
echo "  echo \$ORACLE_SID"
echo ""
echo "To test the oracle user environment:"
echo "  su - oracle"
echo "  source ~/.bash_profile"
echo "  echo \$ORACLE_SID" 