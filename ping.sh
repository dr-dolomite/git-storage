#!/bin/ash
ping_count=5
ping_interval=10
ping_targets="google.com 1.1.1.1"
reboot_command="reboot"

consecutive_failures=0

while true; do
    all_targets_failed=false

    for target in $ping_targets; do
        echo "Pinging $target..."
        ping_fail_count=0

        for i in $(seq 1 $ping_count); do
            if ping -c 1 -W $ping_interval "$target" >/dev/null 2>&1; then
                echo "Ping to $target successful."
                break
            fi

            echo "Ping to $target failed ($i/$ping_count)."
            ping_fail_count=$((ping_fail_count + 1))

            # Add a 5-second interval between failed pings
            sleep 5
        done

        if [ "$ping_fail_count" -ge "$ping_count" ]; then
            echo "Ping to $target failed $ping_count times."
            all_targets_failed=true
            break
        fi

        # Add a 3-second pause between ping targets
        sleep 3
    done

    if [ "$all_targets_failed" = true ]; then
        consecutive_failures=$((consecutive_failures + 1))

        if [ "$consecutive_failures" -eq 1 ]; then
            echo "First consecutive failure. Sending AT command and sleeping for 30 seconds."
            echo -ne 'AT+CFUN=1,1 \r' | microcom -X -t 1000 /dev/ttyUSB2 >/dev/null 2>&1
            sleep 40
        elif [ "$consecutive_failures" -eq 2 ]; then
            echo "Second consecutive failure. Sending AT command again and sleeping for 30 seconds."
            echo -ne 'AT+CFUN=1,1 \r' | microcom -X -t 1000 /dev/ttyUSB2 >/dev/null 2>&1
            sleep 40
        else
            echo "Third consecutive failure. Rebooting the router."
            $reboot_command
            exit
        fi
    else
        consecutive_failures=0
    fi
done