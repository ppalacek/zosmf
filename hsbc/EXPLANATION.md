# DB2 V13 Maintenance Workflow - Manager's Guide

## What This Workflow Does

This workflow automates the process of receiving software updates (called "maintenance" or "PTFs") for DB2 Version 13 and related database tools. Think of it like receiving and organizing software patches for your database system before they get installed.

---

## The 8 Steps Explained

### Step 1: Validate Prerequisites
**What it does:** Checks that all necessary storage areas and configuration files exist before starting.

**Why it matters:** Like checking you have all the ingredients before cooking - this prevents failures halfway through the process. It verifies that:
- Storage locations for software updates are ready
- Configuration databases are properly set up
- All required file systems are available

**What to look for:** The job should complete successfully showing that all required datasets exist. If anything is missing, you'll need to create those storage areas before continuing.

---

### Step 2: Receive DB2 V13 Core Maintenance
**What it does:** Downloads and receives IBM DB2 core product updates from IBM's software distribution service (ShopZ).

**Why it matters:** This is the main DB2 database software update. It's like downloading Windows updates directly from Microsoft - getting the latest fixes and improvements for the core database product.

**The process:**
1. Mounts a storage area (like plugging in a USB drive)
2. Downloads updates from IBM's ShopZ service (from two different orders to ensure nothing is missed)
3. Stores the updates in the proper location
4. Unmounts the storage area when done

**What to look for:** The job should complete with no major errors (return code 4 or less). Check the output to see which updates were successfully received.

---

### Step 3: Receive IBM DB2 Tools Maintenance
**What it does:** Downloads and receives updates for IBM's official DB2 utilities and tools.

**Why it matters:** DB2 comes with various management and monitoring tools. This step updates those tools - like updating Excel while also updating Office utilities.

**The process:**
1. Mounts two storage areas (one for the updates, one for temporary work space)
2. Downloads tool updates from IBM's ShopZ service
3. Stores the updates properly
4. Unmounts both storage areas

**What to look for:** Similar to Step 2 - successful completion with return code 4 or less. Verify that tool updates were received.

---

### Step 4: Report DB2 Core Error SYSMODs
**What it does:** Generates two important reports about the DB2 core product updates:
- Which updates have problems (marked as "in error")
- Which recommended updates are missing

**Why it matters:** This is your quality check. It tells you:
- If any updates you already applied now have known issues
- What IBM-recommended updates you don't have yet
- Whether you need to take corrective action

**What to look for:** Review the reports to see if there are any error conditions or missing critical fixes. Share these reports with your technical team for evaluation.

---

### Step 5: Report IBM DB2 Tools Error SYSMODs
**What it does:** Same as Step 4, but for the IBM DB2 Tools instead of the core product.

**Why it matters:** Ensures your DB2 management tools are up-to-date and problem-free.

**What to look for:** Check for any tools updates with errors or missing recommended fixes.

---

### Step 6: Receive Broadcom DB2 Tools Maintenance *(Optional)*
**What it does:** Downloads and receives updates for third-party DB2 tools from Broadcom (formerly Computer Associates).

**Why it matters:** If your organization uses Broadcom's DB2 tools, this step keeps them current. If you don't use these tools, you can skip this step.

**The process:**
1. Mounts storage for Broadcom tool updates
2. Downloads updates from Broadcom's distribution service
3. Stores the updates
4. Unmounts storage

**What to look for:** Only relevant if you use Broadcom tools. Should complete successfully if enabled.

---

### Step 7: Download and Receive Broadcom HOLDDATA *(Optional)*
**What it does:** Downloads a special file from Broadcom that contains information about:
- Updates that have known problems
- Which updates fix which problems
- Categories of fixes available

**Why it matters:** This is like downloading a catalog that tells you about issues with Broadcom updates and what fixes are available. The system uses this information to generate accurate reports about what's missing or problematic.

**The process:**
1. Deletes the old catalog file (if it exists)
2. Uses FTP to download the current catalog from Broadcom's support website
3. Loads the catalog information into the system

**What to look for:** Successful download and processing of the HOLDDATA file. Note: This requires internet/FTP access to Broadcom's support site.

---

### Step 8: Report Broadcom Tools Error SYSMODs *(Optional)*
**What it does:** Generates reports about Broadcom tool updates (same concept as Steps 4 and 5).

**Why it matters:** Quality check for Broadcom tools - identifies problem updates and missing recommended fixes.

**What to look for:** Review reports for Broadcom-specific issues or missing fixes.

---

## Summary of Workflow Benefits

1. **Automation:** What used to require manual intervention is now automated
2. **Consistency:** Same process every time, reducing human error
3. **Documentation:** Each step is tracked and reported
4. **Quality Control:** Built-in error checking and reporting
5. **Efficiency:** Can process multiple update sources in one workflow

## What Success Looks Like

- All validation checks pass (Step 1)
- Updates successfully downloaded from IBM (Steps 2-3)
- Reports generated showing status of all updates (Steps 4-5)
- If using Broadcom tools: Updates downloaded and reports generated (Steps 6-8)
- All jobs complete with acceptable return codes (0-4)

## When to Run This Workflow

- After IBM releases new maintenance levels
- Quarterly as part of regular maintenance schedule
- Before major DB2 upgrades
- When directed by IBM support
- As part of your change management process

## Required Follow-up Actions

After this workflow completes, you still need to:
1. Review all error and missing fix reports with your technical team
2. Decide which updates to actually install (this workflow only receives/downloads them)
3. Schedule the actual installation (APPLY) of selected updates
4. Test the updates in a non-production environment first

---

## Technical Notes for Managers

- **Return Code 0-4:** Generally acceptable completion status
- **Return Code 8 or higher:** Indicates errors that need investigation
- **Optional Steps:** Steps 6-8 only apply if you use Broadcom DB2 tools
- **Duration:** Depending on the amount of maintenance, this can take 30 minutes to several hours
- **Prerequisites:** Requires proper security permissions and configured access to IBM/Broadcom download sites
