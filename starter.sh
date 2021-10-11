#!/bin/bash

docker-compose --env-file="./.env" -f ./docker-compose.yml up -d
docker-compose --env-file="./.env" -f ./docker-compose.mariadb.yml up -d
docker-compose --env-file="./.env" -f ./docker-compose.redis.yml up -d
docker-compose --env-file="./.env" -f ./backend/docker-compose.yml -f ./docker-compose.api.yml up -d
docker-compose --env-file="./.env" -f ./frontend/docker-compose.yml -f ./docker-compose.webgest.yml up -d

exit
dev=false
help=false
push=false
build=false
stop=false
up_services=false

BLUE='\033[1;34m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
LGRAY='\033[0;37m'
NC='\033[0m' # No Color

get_help(){
    printf "\n${GREEN}Tranquillo, ci penso io!${NC}\n"

    echo -e "
    -h: ${PURPLE}help${NC} Questo help!
    -d: ${PURPLE}dev${NC} lancia i vari container con il docker-compose e i docker file di dev
    -b: ${PURPLE}build${NC} prepara le immagini per il rilascio (adesso fa anche up)
    -p: ${PURPLE}push${NC} Momentaneamente non fa un caBBo
    -u: ${PURPLE}up${NC} Ancora non fa niente
    -s: ${PURPLE}stop${NC} concatenato a -d o -b fa il down prima di startare nuovamente.

    Un ciaone..
    Andrea";
}

# DDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEEPPPPPPPPPPPPPPPPP   LLLLLLLLLLL                  OOOOOOOOO     YYYYYYY       YYYYYYY
# D::::::::::::DDD   E::::::::::::::::::::EP::::::::::::::::P  L:::::::::L                OO:::::::::OO   Y:::::Y       Y:::::Y
# D:::::::::::::::DD E::::::::::::::::::::EP::::::PPPPPP:::::P L:::::::::L              OO:::::::::::::OO Y:::::Y       Y:::::Y
# DDD:::::DDDDD:::::DEE::::::EEEEEEEEE::::EPP:::::P     P:::::PLL:::::::LL             O:::::::OOO:::::::OY::::::Y     Y::::::Y
#   D:::::D    D:::::D E:::::E       EEEEEE  P::::P     P:::::P  L:::::L               O::::::O   O::::::OYYY:::::Y   Y:::::YYY
#   D:::::D     D:::::DE:::::E               P::::P     P:::::P  L:::::L               O:::::O     O:::::O   Y:::::Y Y:::::Y   
#   D:::::D     D:::::DE::::::EEEEEEEEEE     P::::PPPPPP:::::P   L:::::L               O:::::O     O:::::O    Y:::::Y:::::Y    
#   D:::::D     D:::::DE:::::::::::::::E     P:::::::::::::PP    L:::::L               O:::::O     O:::::O     Y:::::::::Y     
#   D:::::D     D:::::DE:::::::::::::::E     P::::PPPPPPPPP      L:::::L               O:::::O     O:::::O      Y:::::::Y      
#   D:::::D     D:::::DE::::::EEEEEEEEEE     P::::P              L:::::L               O:::::O     O:::::O       Y:::::Y       
#   D:::::D     D:::::DE:::::E               P::::P              L:::::L               O:::::O     O:::::O       Y:::::Y       
#   D:::::D    D:::::D E:::::E       EEEEEE  P::::P              L:::::L         LLLLLLO::::::O   O::::::O       Y:::::Y       
# DDD:::::DDDDD:::::DEE::::::EEEEEEEE:::::EPP::::::PP          LL:::::::LLLLLLLLL:::::LO:::::::OOO:::::::O       Y:::::Y       
# D:::::::::::::::DD E::::::::::::::::::::EP::::::::P          L::::::::::::::::::::::L OO:::::::::::::OO     YYYY:::::YYYY    
# D::::::::::::DDD   E::::::::::::::::::::EP::::::::P          L::::::::::::::::::::::L   OO:::::::::OO       Y:::::::::::Y    
# DDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEEPPPPPPPPPP          LLLLLLLLLLLLLLLLLLLLLLLL     OOOOOOOOO         YYYYYYYYYYYYY   

stop_builded(){
    FAIL=0
    docker container prune -f &
    docker network prune -f &



    printf "\n${LGRAY}Spengo i container attivi${NC}\n"
    docker compose -f ./api/docker-compose.yml -f ./web/docker-compose.api.yml --env-file="./web/.env" down &
    docker compose -f ./webgest/docker-compose.yml -f ./web/docker-compose.webgest.yml --env-file="./web/.env" down &
    docker compose -f ./webtrax/docker-compose.yml -f ./web/docker-compose.webtrax.yml --env-file="./web/.env" down &
    docker compose -f ./web/docker-compose.yml --env-file="./web/.env" down &
    docker compose -f ./web/docker-compose.mariadb.yml --env-file="./web/.env" down &
    docker compose -f ./web/docker-compose.redis.yml --env-file="./web/.env" down &

    for job in `jobs -p`
    do
    echo $job
        wait $job || let "FAIL+=1"
        docker container prune -f
        docker network prune -f
    done
}

start_build(){
    FAIL=0
    printf "${LGRAY}ReverseProxy${NC}\n"
    docker compose -f ./web/docker-compose.yml --env-file="./web/.env" up --build -d 
    printf "${LGRAY}MariaDB${NC}\n"
    docker compose -f ./web/docker-compose.mariadb.yml --env-file="./web/.env" up --build -d 
    printf "${LGRAY}Redis${NC}\n"
    docker compose -f ./web/docker-compose.redis.yml --env-file="./web/.env" up --build -d 
    printf "${LGRAY}API${NC}\n"
    docker compose -f ./api/docker-compose.yml -f ./web/docker-compose.api.yml --env-file="./web/.env" up --build -d &
    printf "${LGRAY}WebGest${NC}\n"
    docker compose -f ./webgest/docker-compose.yml -f ./web/docker-compose.webgest.yml --env-file="./web/.env" up --build -d &
    printf "${LGRAY}WebTrax${NC}\n"
    docker compose -f ./webtrax/docker-compose.yml -f ./web/docker-compose.webtrax.yml --env-file="./web/.env" up --build -d &

    for job in `jobs -p`
    do
    echo $job
        wait $job || let "FAIL+=1"
    done
}

# DDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEEVVVVVVVV           VVVVVVVV     MMMMMMMM               MMMMMMMM     OOOOOOOOO     DDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEE
# D::::::::::::DDD   E::::::::::::::::::::EV::::::V           V::::::V     M:::::::M             M:::::::M   OO:::::::::OO   D::::::::::::DDD   E::::::::::::::::::::E
# D:::::::::::::::DD E::::::::::::::::::::EV::::::V           V::::::V     M::::::::M           M::::::::M OO:::::::::::::OO D:::::::::::::::DD E::::::::::::::::::::E
# DDD:::::DDDDD:::::DEE::::::EEEEEEEEE::::EV::::::V           V::::::V     M:::::::::M         M:::::::::MO:::::::OOO:::::::ODDD:::::DDDDD:::::DEE::::::EEEEEEEEE::::E
#   D:::::D    D:::::D E:::::E       EEEEEE V:::::V           V:::::V      M::::::::::M       M::::::::::MO::::::O   O::::::O  D:::::D    D:::::D E:::::E       EEEEEE
#   D:::::D     D:::::DE:::::E               V:::::V         V:::::V       M:::::::::::M     M:::::::::::MO:::::O     O:::::O  D:::::D     D:::::DE:::::E             
#   D:::::D     D:::::DE::::::EEEEEEEEEE      V:::::V       V:::::V        M:::::::M::::M   M::::M:::::::MO:::::O     O:::::O  D:::::D     D:::::DE::::::EEEEEEEEEE   
#   D:::::D     D:::::DE:::::::::::::::E       V:::::V     V:::::V         M::::::M M::::M M::::M M::::::MO:::::O     O:::::O  D:::::D     D:::::DE:::::::::::::::E   
#   D:::::D     D:::::DE:::::::::::::::E        V:::::V   V:::::V          M::::::M  M::::M::::M  M::::::MO:::::O     O:::::O  D:::::D     D:::::DE:::::::::::::::E   
#   D:::::D     D:::::DE::::::EEEEEEEEEE         V:::::V V:::::V           M::::::M   M:::::::M   M::::::MO:::::O     O:::::O  D:::::D     D:::::DE::::::EEEEEEEEEE   
#   D:::::D     D:::::DE:::::E                    V:::::V:::::V            M::::::M    M:::::M    M::::::MO:::::O     O:::::O  D:::::D     D:::::DE:::::E             
#   D:::::D    D:::::D E:::::E       EEEEEE        V:::::::::V             M::::::M     MMMMM     M::::::MO::::::O   O::::::O  D:::::D    D:::::D E:::::E       EEEEEE
# DDD:::::DDDDD:::::DEE::::::EEEEEEEE:::::E         V:::::::V              M::::::M               M::::::MO:::::::OOO:::::::ODDD:::::DDDDD:::::DEE::::::EEEEEEEE:::::E
# D:::::::::::::::DD E::::::::::::::::::::E          V:::::V               M::::::M               M::::::M OO:::::::::::::OO D:::::::::::::::DD E::::::::::::::::::::E
# D::::::::::::DDD   E::::::::::::::::::::E           V:::V                M::::::M               M::::::M   OO:::::::::OO   D::::::::::::DDD   E::::::::::::::::::::E
# DDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEE            VVV                 MMMMMMMM               MMMMMMMM     OOOOOOOOO     DDDDDDDDDDDDD      EEEEEEEEEEEEEEEEEEEEEE

stop_dev(){
    printf "\n${LGRAY}Spengo i container attivi in dev${NC}\n"
    docker compose -f ./web/docker-compose.dev.yml --env-file="./web/.env.dev" down --volumes
}

start_dev(){
    docker compose -f ./web/docker-compose.dev.yml --env-file="./web/.env.dev" up -d
}

while getopts dpbhs flag
do
    case "${flag}" in
        d) dev=true;;
        b) build=true;;
        p) push=true;;
        u) up_services=true;;
        s) stop=true;;
        h) help=true;;
    esac
done


if [ "$help" == true ]
then
    get_help
    exit
fi


if [ "$dev" == true ]
then
    printf "${PURPLE}Benvenuto, sei in DEV${NC}\n"
    printf "${LGRAY}In bocca al lupo${NC}\n"

    if [ "$stop" == true ]
    then
        stop_dev
    fi

    start_dev
    exit
fi


if [ "$build" == true ]
then    
    printf "${PURPLE}Ciao, sei in build${NC}\n"
    printf "${LGRAY}Sto rilascio tutto liscio!${NC}\n"

    if [ "$build" == true ]
    then
        if [ "$stop" == true ]
        then
        stop_builded
        fi
        start_build
    fi
fi
