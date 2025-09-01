# DynDNS Auto-Updater

Automatically monitors your server's public IP and updates DynDNS hosts only when the IP changes.  
Provides clean logging of IP changes, execution counts for unchanged IPs, and readable screen output.

---

## 📂 Repository Structure

```
/dyndns
├─ dyndns-credentials.csv    # Host/user/password credentials
├─ dyndns-ip-records.txt     # Persistent record of last known IPs
├─ dyndns-update.log         # Log of IP changes
├─ dyndns-update.sh          # Main update script
```

### File Overview

- **dyndns-credentials.csv**  
  Contains host credentials in the format: `host,user,password`.  
  Example:
  ```csv
  your.host.fqdn,your-dyndns-username,your-dyndns-password
  ```

- **dyndns-ip-records.txt**  
  Stores the last known IP, last update timestamp, number of consecutive executions where the IP remained unchanged, and the first timestamp of that period.  
  Example:
  ```
  your.host.fqdn 79.31.228.204 2025-09-01 09:00:01 4319 2025-08-28 14:03:22
  ```

- **dyndns-update.log**  
  Logs only meaningful events: IP changes or errors.  
  Example:
  ```
  [2025-09-01 09:00:01] Host: your.host.fqdn - IP changed from 79.31.228.204 to 79.31.229.50
    Stable period: 2025-08-28 14:03:22 → 2025-09-01 08:59:01 (4319 executions, duration 3 days)
    DynDNS response: good 79.31.229.50
  ```

- **dyndns-update.sh**  
  Bash script implementing the monitoring and updating logic.

---

## ⚙️ How It Works

1. Reads host credentials from `dyndns-credentials.csv`.
2. Retrieves the **server's public IP** using [ipify](https://api.ipify.org), not the resolved DNS of the host.
3. Compares the current IP to the last recorded IP in `dyndns-ip-records.txt`.
4. If the IP is unchanged:
   - Increments a counter for consecutive unchanged executions.
   - Prints human-readable output to the screen (minutes/hours/days).
5. If the IP has changed:
   - Updates DynDNS via `curl`.
   - Logs a detailed block with:
     - Old and new IP
     - Duration and number of executions of the previous stable period
     - DynDNS response
   - Updates the record file.

---

## 🖥️ Example Screen Output

```
Host: your.host.fqdn - IP unchanged (79.31.228.204) for 12 hours
Host: your.host.fqdn - IP unchanged (79.31.222.180) for 2 days
```

---

## 📄 Example Log Entry

```
[2025-09-01 09:00:01] Host: your.host.fqdn - IP changed from 79.31.228.204 to 79.31.229.50
  Stable period: 2025-08-28 14:03:22 → 2025-09-01 08:59:01 (4319 executions, duration 3 days)
  DynDNS response: good 79.31.229.50
```

---

## 🛠️ Installation and Usage

1. Clone the repository:
```bash
git clone <REPO_URL>
cd dyndns
```

2. Make the script executable:
```bash
chmod +x dyndns-update.sh
```

3. Configure your host credentials in `dyndns-credentials.csv`.

4. Test the script manually:
```bash
./dyndns-update.sh
```

5. Schedule periodic execution using `cron` (example: every minute):
```bash
* * * * * /your/folder/dyndns/dyndns-update.sh
```

---

## 🔐 Security

- Restrict permissions on sensitive files:
```bash
chmod 600 dyndns-credentials.csv
```
- Limit access to the folder containing scripts, logs, and IP records.

---

## 📈 Benefits

- Only updates DynDNS when necessary (reduces unnecessary requests).  
- Maintains a clean and readable log.  
- Provides real-time screen output for monitoring.  
- Tracks historical IPs and period durations.  
- Supports multiple hosts via a simple CSV file.

---

## 💡 Potential Enhancements

- Send notifications on IP changes (email, Telegram, Slack).  
- Export logs or records in JSON for monitoring integration.  
- Visualize IP stability over time with Grafana dashboards.

---

## 📌 Notes

- Log file (`dyndns-update.log`) can grow large. Use `logrotate` if needed.  
- Ensure `curl` and `bash` are installed on the server.  
- The script relies on the public IP provided by your ISP, retrieved via `https://api.ipify.org`.
