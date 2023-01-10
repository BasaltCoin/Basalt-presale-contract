#!/bin/bash
truffle migrate --reset --network $1
echo "please wait...30 sec"
sleep 30
#truffle run verify MockERC20 --network $1
truffle run verify BasaltToken --network $1
truffle run verify BasaltTokenSale --network $1

echo "done"