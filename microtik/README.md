# Mikrotik

## Router

- Connect to Router using cable or Wi-Fi (e.g., SSID - MikroTik-A2441A)


- Local Network - 10.0.0.0/24
    - Open http://192.168.88.1/ - default MikroTik IP  
      Login: **admin**  
      Password: *(empty)*
    - Select **[Quick Set]** mode  
      Press **[Cancel]** - do not change the "admin" password

      | Key                | Value                |
      |--------------------|----------------------|
      | IP Address         | 10.0.0.1             |
      | DHCP Server Range  | 10.0.0.10-10.0.0.100 | 

    - **[Apply Configuration]** - Wi-Fi restarts
    - Reconnect to Wi-Fi if required


- User Management
    - Open http://10.0.0.1/  
      Login: **admin**  
      Password: *(empty)*
    - Select **[Advanced]** mode
    - **System / Users / [ New ]**

      | Key              | Value           |
      |------------------|-----------------|
      | Name             | router_user     |
      | Group            | full            |
      | Password         | *************** | 
      | Confirm Password | *************** | 

    - Logout - Top Right **[ ⁝ ] / [ Logout ]**
    - Open http://10.0.0.1/  
      Login: **router_user**  
      Password: ***************
    - Remove **admin** user  
      **System / Users / [ Remove ]**


- Home Wi-Fi
    - **Wireless / Wireless / [ WiFi Interfaces ]**  
      **wlan1** edit

      | Key      | Value     |
      |----------|-----------|
      | Name     | wifi 2.4G |
      | SSID     | gm        |
      | WPS Mode | disabled  | 

    - Reload http://10.0.0.1/ (if Wi-Fi restarted)
    - **Wireless / Wireless / [ WiFi Interfaces ]**  
      **wlan2** edit

      | Key      | Value    |
      |----------|----------|
      | Name     | wifi 5G  |
      | SSID     | gm       |
      | WPS Mode | disabled | 

    - Set Home Wi-Fi Password  
      **Wireless / Wireless / Security Profiles**  
      Edit **default** Security Profile

      | Key                  | Value            |
      |----------------------|------------------|
      | Mode                 | dynamic keys     |
      | Authentication Types | WPA2 PSK         |
      | Unicast Ciphers      | aes ccm          |
      | Group Ciphers        | aes ccm          |
      | WPA2 Pre-Shared Key  | ***************  |

    - Reload http://10.0.0.1/ (if Wi-Fi restarted)


- Guest Wi-Fi
    - Set Guest Wi-Fi Password  
      **Wireless / Wireless / Security Profiles / [ New ]**

      | Key                    | Value           |
      |------------------------|-----------------|
      | Name                   | guest           |
      | Mode                   | dynamic keys    |
      | Authentication Types   | WPA2 PSK        |
      | Unicast Ciphers        | aes ccm         |
      | Group Ciphers          | aes ccm         |
      | WPA2 Pre-Shared Key    | *************** |

    - **Wireless / Wireless / WiFi Interfaces / [ New ] / Virtual**

      | Key              | Value         |
      |------------------|---------------|
      | Name             | wifi 5G guest |
      | SSID             | gm guest      |
      | Master Interface | wifi 5G       |
      | Security Profile | guest         |
      | WPS Mode         | disabled      |
      | Default Forward  | false         |

    - **Bridge / [ New ]**

      | Key   | Value         |
      |-------|---------------|
      | Name  | bridge-guest  |

    - **Bridge / Ports / [ New ]**

      | Key       | Value         |
      |-----------|---------------|
      | Interface | wifi 5G guest |
      | Bridge    | bridge-guest  |

    - **IP / Addresses / [ New ]**

      | Key       | Value         |
      |-----------|---------------|
      | Address   | 10.0.10.1/24  |
      | Interface | bridge-guest  |

    - **IP / DHCP Server / [ DHCP Setup ]**

      | Key                    | Value         |
      |------------------------|---------------|
      | DHCP Server Interface  | bridge-guest  |


- Static IP Addresses <br>
  **IP / DHCP Server / Leases** - Click on the record; **[ Make Static ]** <br>
  **IP / DHCP Server / Leases** - Click on the record; **Update Address**

  | IP        | Device  |
  |-----------|---------|
  | 10.0.0.11 | Printer |
  | 10.0.0.14 | rpi4    |
  | 10.0.0.15 | rpi5    |


- Port Forwarding
  ```console
  /ip firewall address-list add list=vpn_clients address=10.0.20.0/24 comment="  :: IPSec VPN clients"
  /ip firewall nat add chain=dstnat protocol=tcp dst-port=443 in-interface=ether1 src-address-list=!vpn_clients action=dst-nat to-addresses=10.0.0.15 to-ports=443 comment="  :: https"
  ```


- DNS Servers - in case there are DNS Servers in the network, example [Pi Hole](https://pi-hole.net)
  ```console
  /ip dhcp-server network set [find address=10.0.0.0/24] dns-server=10.0.0.15,10.0.0.14
  ```


- IPTV (Moldtelecom)
    - **Interfaces / VLAN / [ New ]**

      | Key       | Value     |
      |-----------|-----------|
      | Name      | vlan-IPTV |
      | VLAN ID   | 35        |
      | Interface | ether1    |

    - **Bridge / [ New ]**

      | Key           | Value       |
      |---------------|-------------|
      | Name          | bridge-IPTV |
      | Protocol mode | none        |

    - **Bridge / Ports / [ New ]**

      | Key       | Value       |
      |-----------|-------------|
      | Interface | vlan-IPTV   |
      | Bridge    | bridge-IPTV |

    - **Bridge / Ports** - update Bridge for IPTV Interface, e.g., **ether4**

      | Key    | Value        |
      |--------|--------------|
      | ether4 | bridge-IPTV  |


- Local SSH Connection
    - Create keys on the local machine
      ```console
      ssh-keygen -t ed25519 -f ~/.ssh/local_user@pro-10.0.0.1 -C "local_user@10.0.0.1 MacBook Pro"
      ```

    - Upload the public key to the router  
      **Files / File / [ Upload... ]**

    - Attach the public key to the **router_user** MikroTik user  
      **System / Users / SSH Keys / [ Import SSH Key ]**

      | Key      | Value                       |
      |----------|-----------------------------|
      | User     | router_user                 |
      | Key File | local_user@pro-10.0.0.1.pub |

    - Configure the local **~/.ssh/config** file
      ```console
      vim ~/.ssh/config
      ```
      ```
      Host mikrotik
      HostName 10.0.0.1
      User router_user
      IdentityFile ~/.ssh/local_user@pro-10.0.0.1
      ```

    - Connect from local machine
      ```console
      ssh mikrotik
      ```

    - Close MikroTik session
      ```console
      quit
      ```


- Fine Tuning
  ```console
  /system clock set time-zone-name=Europe/Chisinau
  /system ntp client set enabled=yes servers=pool.ntp.org,second.pool.ntp.org mode=unicast
  /ip service disable api,api-ssl,ftp,telnet,winbox
  ```


- Certificates - Execute on MikroTik Console
    - Root
      ```console
      /certificate add name=CA.(domain).com country=MD locality=Chisinau organization=home common-name=ca.(domain).com subject-alt-name=DNS:ca.(domain).com key-size=4096 days-valid=3650 trusted=yes key-usage=digital-signature,key-encipherment,data-encipherment,key-cert-sign,crl-sign
      /certificate sign CA.(domain).com
      /certificate export-certificate CA.(domain).com type=pem
      ```

    - SSL
      ```console
      /certificate add name=ssl@(domain).com country=MD locality=Chisinau organization=home common-name=10.0.0.1 key-size=2048 days-valid=1095 trusted=yes
      /certificate sign ssl@(domain).com ca=CA.(domain).com
      /certificate export-certificate ssl@(domain).com type=pkcs12 export-passphrase=8e6a25785da4f9e63185
  
      /ip service set www-ssl certificate=ssl@(domain).com disabled=no
      ```

    - Import SSL Certificate on the local machine (browsers)  
      **Files / cert_export_ssl@(domain).com.p12 / [ Download ]**


- Trusted VPN
    - Troubleshooting
      ```console
      /system logging add topics=ipsec action=memory
      ```

    - IPSec
      ```console
      /ip pool add name=pool-vpn ranges=10.0.20.10-10.0.20.100
  
      /certificate add name=vpn.(domain).com country=MD locality=Chisinau organization=home common-name=vpn.(domain).com subject-alt-name=DNS:vpn.(domain).com key-size=2048 days-valid=1095 trusted=yes key-usage=tls-server
      /certificate sign vpn.(domain).com ca=CA.(domain).com
  
      /certificate add name=vpn.(domain).com country=MD locality=Chisinau organization=home common-name=vpn.(domain).com subject-alt-name=DNS:vpn.(domain).com key-size=2048 days-valid=1095 trusted=yes key-usage=tls-server
      /certificate sign vpn.(domain).com ca=CA.(domain).com
    
      /ip ipsec profile add name=ikev2-profile hash-algorithm=sha256 enc-algorithm=aes-256 dh-group=modp2048
      /ip ipsec proposal add name=ikev2-proposal auth-algorithms=sha256 enc-algorithms=aes-256-cbc pfs-group=none
      /ip ipsec mode-config add name=modeconf-ikev2 address-pool=pool-vpn address-prefix-length=32 split-include=0.0.0.0/0
      /ip ipsec policy group add name=ikev2-group
      /ip ipsec policy add src-address=0.0.0.0/0 dst-address=10.0.20.0/24 group=ikev2-group proposal=ikev2-proposal template=yes
      /ip ipsec peer add name=ikev2-peer profile=ikev2-profile exchange-mode=ike2 passive=yes
      ```

    - Firewall
      ```console
      /ip firewall filter add chain=input dst-port=500,4500 protocol=udp action=accept place-before=[ find where comment~"defconf: drop all not coming from LAN" ] comment="  :: Allow UDP 500,4500 IPSec"
      /ip firewall filter add chain=input protocol=ipsec-esp action=accept place-before=[ find where comment~"defconf: drop all not coming from LAN" ] comment="  :: Allow IPSec-esp"
  
      /ip firewall filter add chain=forward ipsec-policy=in,ipsec action=jump jump-target=ipsec-in place-before=[ find where comment~"defconf: drop all not coming from LAN" ] comment="  :: VPN -> LAN"
      /ip firewall filter add chain=forward ipsec-policy=out,ipsec action=jump jump-target=ipsec-out place-before=[ find where comment~"defconf: drop all not coming from LAN" ] comment="  :: LAN -> VPN"
  
      /ip firewall filter add chain=input ipsec-policy=in,ipsec action=accept src-address=10.0.20.0/24 place-before=[ find where comment~"defconf: drop all not coming from LAN" ] comment="  :: VPN -> Router"
      ```

    - Each Trusted User
      ```console
      /certificate add name=(ipsec_user)@vpn.(domain).com country=MD locality=Chisinau organization=home common-name=(ipsec_user)@vpn.(domain).com subject-alt-name=email:(ipsec_user)@vpn.(domain).com key-size=2048 days-valid=730 trusted=yes key-usage=tls-client
      /certificate sign (ipsec_user)@vpn.(domain).com ca=CA.(domain).com
      /certificate export-certificate (ipsec_user)@vpn.(domain).com type=pkcs12 export-passphrase=8e6a25785da4f9e63185
  
      /ip ipsec identity add peer=ikev2-peer auth-method=digital-signature certificate=vpn.(domain).com remote-certificate=(ipsec_user)@vpn.(domain).com policy-template-group=ikev2-group remote-id=user-fqdn:(ipsec_user)@vpn.(domain).com match-by=certificate mode-config=modeconf-ikev2 generate-policy=port-strict comment="(ipsec_user)@vpn.(domain).com"
      ```


- Client Configuration  
  **Files / cert_export_CA.(domain).com.crt / [ Download ]**  
  **Files / cert_export_(ipsec_user).vpn.(domain).com.p12 / [ Download ]**

    - iOS <br>
      Import certificates - copy files into iCloud Drive, from iPhone / iPad open iCloud Drive, click on certificates and import them; <br>
      From **Settings / Profile Downloaded** install all certificates.  <br>
      Create **VPN Connection** - **Settings / General / VPN & Device Management / VPN / Add VPN Configuration**

      | Key             | Value                          |
      |-----------------|--------------------------------|
      | Type            | IKEv2                          |
      | Description     | Home VPN                       |
      | Server          | vpn.(domain).com               |
      | Remote ID       | vpn.(domain).com               |
      | Local ID        | (ipsec_user)@vpn.(domain).com  |
      |                 |                                |
      | User Auth       | None                           |
      | Use Certificate | Yes                            |
      | Certificate     | (ipsec_user)@vpn.(domain).com  |

    - macOS <br>
      Import certificates into Keychain  
      **System Settings / VPN / Add VPN Configuration / IKEv2**

      | Key                    | Value                         |
      |------------------------|-------------------------------|
      | Display name           | Home VPN                      |
      | Server address         | vpn.(domain).com              |
      | Remote ID              | vpn.(domain).com              |
      | Local ID               | (ipsec_user)@vpn.(domain).com |
      |                        |                               |
      | User authentication    | None                          |
      | Machine authentication | Certificate                   |
      | Certificate            | (ipsec_user)@vpn.(domain).com |

      **System Settings / Control Center / Menu Bar Only**

      | Key | Value            |
      |-----|------------------|
      | VPN | Show in Menu Bar |
