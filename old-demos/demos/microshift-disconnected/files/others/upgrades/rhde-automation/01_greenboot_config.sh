#!/bin/bash

mkdir -p /etc/greenboot/check/required.d
cat > /etc/greenboot/check/required.d/01_check_microshift.sh <<EOF
#!/bin/bash

microshift --help

EOF

chmod +x /etc/greenboot/check/required.d/01_check_microshift.sh


mkdir -p /etc/greenboot/red.d

cat > /etc/greenboot/red.d/99_send_log.sh <<EOF
#!/bin/bash
for ((i=1; i<=10; i++)); do
    echo "ERROR: Upgrade failed " | sudo tee /dev/consol
done
EOF

chmod +x /etc/greenboot/red.d/99_send_log.sh



mkdir -p /etc/greenboot/green.d

cat > /etc/greenboot/green.d/99_send_log.sh <<EOF
#!/bin/bash
for ((i=1; i<=10; i++)); do
    echo "SYSTEM WAS UPGRADED" | sudo tee /dev/consol
done
EOF

chmod +x /etc/greenboot/green.d/99_send_log.sh
