import { Injectable } from '@angular/core';
import Web3 from "web3";
import { ethers } from 'ethers'

declare const window: any;

@Injectable({
  providedIn: 'root'
})
export class AccountService {
  window: any;
  constructor() {
    if (typeof window.ethereum !== 'undefined') {
      console.log('MetaMask is installed!');
    }
  }

  private getAccounts = async () => {
    try {
      return await window.ethereum.request({ method: 'eth_accounts' });
    } catch (e) {
      return [];
    }
  }

  public getNetwork = async () => {
    try {
      return await window.ethereum.request({ method: 'eth_chainId' });
    } catch (e) {
      return [];
    }
  }

  public disconnect = async () => {
    try{
      return await window.ethereum.on('disconnect');
    }catch (e){
      return [];
    }
  }

  public openMetamask = async () => {
    window.web3 = new Web3(window.ethereum);
    let addresses = await this.getAccounts();
    console.log("service", addresses)
    if (!addresses.length) {
      try {
        addresses = await window.ethereum.enable();
      } catch (e) {
        return false;
      }
    }
    return addresses.length ? addresses[0] : null;
  };

}
