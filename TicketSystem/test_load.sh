#! /bin/bash

# Create users
# for I in {1..3}
# do
#     CARD=$((I % 3))
#     curl -H "Content-Type: application/json" -X POST \
#         -d "{ \"email\": \"user${I}@test.com\", \"password\": \"pass\", \"paymentCardType\": ${CARD} }" \
#         localhost:8080/api/register
# done

# Make orders
echo "Making 100 orders..."
for I in {1..100}
do
    printf "Request ${I}\nResponse: ";
    curl -H "Content-Type: application/json" -H "Authorization: Bearer RYpeeEeMtDV8RLaIIL2S9U5ME5vH9URP" -X POST \
        -d '{ "ticketCount": 1 }' localhost:8080/api/order;
    printf "\n"
done
