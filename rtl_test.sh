#!/bin/bash


if ! dpkg -s rtl-sdr 2>/dev/null | grep 'Status.*installed' &>/dev/null
then
    if ! apt-get install --no-install-recommends --no-install-suggests --reinstall -y rtl-sdr
    then
        echo "Couldn't install rtl-sdr!"
        exit 1
    fi
fi

stop="piaware dump1090-fa dump1090-mutability dump1090 dump978-fa readsb"

systemctl stop fr24feed &>/dev/null


if pgrep -a dump1090 || pgrep -a dump978 || pgrep -a readsb
then
    restart=yes
    for i in $stop
    do
        systemctl stop $i 2>/dev/null
    done
    pkill -9 dump1090
    pkill -9 readsb
    for i in $stop
    do
        systemctl stop $i 2>/dev/null
    done
    pkill -9 dump1090
    pkill -9 readsb
    sleep 1
fi

if pgrep -l dump1090 || pgrep -l readsb
then
    echo "dump1090 aún se está ejecutando, no se puede probar el receptor rtl-sdr, reinicie e intente nuevamente!"
    for i in $stop
    do
        systemctl restart $i 2>/dev/null
    done
    systemctl restart fr24feed &>/dev/null
    exit 1
fi


echo "-----"
echo "Las muestras perdidas en los primeros 2 segundos después de comenzar la prueba son comunes y no son un problema!"
echo "Prueba de 30 segundos rtl_test, en espera!"
echo "-----"

timeout 30 rtl_test -s 2400000

echo "-------"
echo "Prueba terminada!"
echo "Más de 2 muestras perdidas por millón u otros errores probablemente significan que el receptor no funciona correctamente."
echo "Sin embargo, pruebe con otra fuente de alimentación antes de condenar el receptor.!"
echo "-------"

systemctl restart fr24feed &>/dev/null

if [[ $restart == yes ]]
then
    for i in $stop
    do
        systemctl restart $i 2>/dev/null
    done
fi


if dmesg --ctime | grep voltage
then
    echo "-------"
    dmesg --ctime | grep voltage | tail -n15
    echo "-------"
    echo "Su fuente de alimentación no es adecuada, considere la fuente de alimentación de mas potencia."
    echo "Cualquier suministro de voltaje constante con capacidad de 5,1 a 5,2 voltios y 2,5 A también es una buena opción."
    echo "Las fuentes de alimentación inadecuadas pueden conducir a muchos problemas diferentes!"
    echo "-------"
else
    echo "-------"
    echo "No se detectó subtensión, todo ok!"
    echo "Si el dongle no está conectado directamente a la Raspberry Pi, la falta de energía/voltaje aún podría ser un problema."
    echo "Incluso sin subtensión detectada, una mejor fuente de alimentación a menudo puede mejorar la recepción!"
    echo "Para un rendimiento óptimo, recomendaría la fuente de alimentación de calidad y con ptencia minia de 2 amp."
    echo "-------"
fi
