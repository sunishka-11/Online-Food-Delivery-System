import customtkinter as ctk
from tkinter import ttk, messagebox
import mysql.connector
from tkcalendar import DateEntry
import datetime
import os

# ==========================================================
# LOGGING SYSTEM
# ==========================================================
LOG_FILE = "activity_log.txt"

def log_action(action: str):
    """Append a timestamped action to the log file."""
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"[{datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {action}\n")

# ==========================================================
# DATABASE CONNECTION
# ==========================================================
def get_connection():
    try:
        con = mysql.connector.connect(
            host="localhost",
            user="app_admin",             # safer than root
            password="admin_pass",        # change if needed
            database="online_order_system",
            auth_plugin='mysql_native_password'
        )
        return con
    except Exception as e:
        messagebox.showerror("Connection Error", f"MySQL connection failed:\n{e}")
        log_action(f"ERROR: MySQL connection failed — {e}")
        raise

# ==========================================================
# MAIN WINDOW
# ==========================================================
app = ctk.CTk()
app.title("Online Order Management System")
app.geometry("1100x700")
app.configure(fg_color="#f7f9fc")

tabview = ctk.CTkTabview(app, width=1050, height=650)
tabview.pack(pady=20)
tab_customer = tabview.add("Customers")
tab_product = tabview.add("Products")
tab_order = tabview.add("Orders")
tab_reports = tabview.add("Reports")

# ==========================================================
# CUSTOMERS TAB
# ==========================================================
def refresh_customers():
    for i in cust_tree.get_children():
        cust_tree.delete(i)
    con = get_connection()
    cur = con.cursor()
    cur.execute("CALL ReadAllCustomers()")
    for row in cur.fetchall():
        cust_tree.insert("", "end", values=row)
    con.close()
    log_action("ReadAllCustomers() executed")

def add_customer():
    try:
        con = get_connection()
        cur = con.cursor()
        cur.callproc("CreateCustomer", [
            fname_var.get(), lname_var.get(), dob_entry.get_date(),
            city_var.get(), pin_var.get()
        ])
        con.commit()
        refresh_customers()
        messagebox.showinfo("Success", "Customer added successfully!")
        log_action(f"CreateCustomer({fname_var.get()}, {lname_var.get()}) executed")
        con.close()
    except Exception as e:
        messagebox.showerror("Error", str(e))
        log_action(f"ERROR: CreateCustomer failed — {e}")

def update_customer():
    sel = cust_tree.focus()
    if not sel:
        messagebox.showwarning("Select", "Select a customer to update.")
        return
    cid = cust_tree.item(sel, "values")[0]
    con = get_connection()
    cur = con.cursor()
    try:
        cur.callproc("UpdateCustomer", [
            cid, fname_var.get(), lname_var.get(), city_var.get(), pin_var.get()
        ])
        con.commit()
        refresh_customers()
        messagebox.showinfo("Updated", "Customer updated successfully!")
        log_action(f"UpdateCustomer({cid}) executed")
    except Exception as e:
        messagebox.showerror("Error", str(e))
        log_action(f"ERROR: UpdateCustomer failed — {e}")
    finally:
        con.close()

def delete_customer():
    sel = cust_tree.focus()
    if not sel:
        messagebox.showwarning("Select", "Select a customer to delete.")
        return
    cid = cust_tree.item(sel, "values")[0]
    con = get_connection()
    cur = con.cursor()
    try:
        cur.callproc("DeleteCustomer", [cid])
        con.commit()
        refresh_customers()
        messagebox.showinfo("Deleted", "Customer deleted successfully!")
        log_action(f"DeleteCustomer({cid}) executed")
    except Exception as e:
        messagebox.showerror("Error", str(e))
        log_action(f"ERROR: DeleteCustomer failed — {e}")
    finally:
        con.close()

# GUI Layout
frame_cust = ctk.CTkFrame(tab_customer)
frame_cust.pack(fill="both", expand=True, padx=10, pady=10)

fname_var = ctk.StringVar()
lname_var = ctk.StringVar()
city_var = ctk.StringVar()
pin_var = ctk.StringVar()

ctk.CTkLabel(frame_cust, text="First Name").grid(row=0, column=0)
ctk.CTkEntry(frame_cust, textvariable=fname_var).grid(row=0, column=1)
ctk.CTkLabel(frame_cust, text="Last Name").grid(row=1, column=0)
ctk.CTkEntry(frame_cust, textvariable=lname_var).grid(row=1, column=1)
ctk.CTkLabel(frame_cust, text="Date of Birth").grid(row=2, column=0)
dob_entry = DateEntry(frame_cust, date_pattern="yyyy-mm-dd")
dob_entry.grid(row=2, column=1)
ctk.CTkLabel(frame_cust, text="City").grid(row=3, column=0)
ctk.CTkEntry(frame_cust, textvariable=city_var).grid(row=3, column=1)
ctk.CTkLabel(frame_cust, text="Pincode").grid(row=4, column=0)
ctk.CTkEntry(frame_cust, textvariable=pin_var).grid(row=4, column=1)

ctk.CTkButton(frame_cust, text="Add", command=add_customer).grid(row=5, column=0)
ctk.CTkButton(frame_cust, text="Update", command=update_customer).grid(row=5, column=1)
ctk.CTkButton(frame_cust, text="Delete", command=delete_customer).grid(row=5, column=2)
ctk.CTkButton(frame_cust, text="Refresh", command=refresh_customers).grid(row=5, column=3)

cust_tree = ttk.Treeview(frame_cust, columns=("ID","Fname","Lname","DoB","Age","City","Pincode"), show="headings")
for col in ("ID","Fname","Lname","DoB","Age","City","Pincode"):
    cust_tree.heading(col, text=col)
    cust_tree.column(col, width=100)
cust_tree.grid(row=6, column=0, columnspan=5, pady=15, sticky="nsew")
refresh_customers()

# ==========================================================
# ORDERS TAB
# ==========================================================
def place_order():
    try:
        con = get_connection()
        cur = con.cursor()
        cur.callproc("PlaceOrder", [cid_ord.get(), sid_ord.get(), item_ord.get(), did_ord.get(), qty_ord.get()])
        con.commit()
        messagebox.showinfo("Success", "Order placed successfully!")
        log_action(f"PlaceOrder(CID={cid_ord.get()}, Item={item_ord.get()}) executed")
    except Exception as e:
        messagebox.showerror("Error", str(e))
        log_action(f"ERROR: PlaceOrder failed — {e}")
    con.close()

def cancel_order():
    try:
        con = get_connection()
        cur = con.cursor()
        cur.callproc("CancelOrder", [oid_cancel.get()])
        con.commit()
        messagebox.showinfo("Cancelled", "Order cancelled successfully!")
        log_action(f"CancelOrder(OID={oid_cancel.get()}) executed")
    except Exception as e:
        messagebox.showerror("Error", str(e))
        log_action(f"ERROR: CancelOrder failed — {e}")
    con.close()

# GUI for Orders
frame_order = ctk.CTkFrame(tab_order)
frame_order.pack(fill="both", expand=True, padx=20, pady=20)

cid_ord = ctk.IntVar()
sid_ord = ctk.IntVar()
did_ord = ctk.IntVar()
qty_ord = ctk.IntVar()
item_ord = ctk.StringVar()
oid_cancel = ctk.IntVar()

ctk.CTkLabel(frame_order, text="Customer ID").grid(row=0, column=0)
ctk.CTkEntry(frame_order, textvariable=cid_ord).grid(row=0, column=1)
ctk.CTkLabel(frame_order, text="Seller ID").grid(row=1, column=0)
ctk.CTkEntry(frame_order, textvariable=sid_ord).grid(row=1, column=1)
ctk.CTkLabel(frame_order, text="Item").grid(row=2, column=0)
ctk.CTkEntry(frame_order, textvariable=item_ord).grid(row=2, column=1)
ctk.CTkLabel(frame_order, text="Delivery ID").grid(row=3, column=0)
ctk.CTkEntry(frame_order, textvariable=did_ord).grid(row=3, column=1)
ctk.CTkLabel(frame_order, text="Quantity").grid(row=4, column=0)
ctk.CTkEntry(frame_order, textvariable=qty_ord).grid(row=4, column=1)
ctk.CTkButton(frame_order, text="Place Order", command=place_order).grid(row=5, column=0)
ctk.CTkLabel(frame_order, text="Order ID to Cancel").grid(row=6, column=0)
ctk.CTkEntry(frame_order, textvariable=oid_cancel).grid(row=6, column=1)
ctk.CTkButton(frame_order, text="Cancel Order", command=cancel_order).grid(row=7, column=0)

# ==========================================================
# REPORTS TAB
# ==========================================================
def show_orders():
    for i in report_tree.get_children():
        report_tree.delete(i)
    con = get_connection()
    cur = con.cursor()
    cur.execute("CALL GetOrdersJoinDetails()")
    for row in cur.fetchall():
        report_tree.insert("", "end", values=row)
    con.close()
    log_action("GetOrdersJoinDetails() executed (JOIN query)")

def total_spent():
    cid = cid_total.get()
    con = get_connection()
    cur = con.cursor()
    cur.execute(f"SELECT GetCustomerTotalSpent({cid});")
    total = cur.fetchone()[0]
    con.close()
    messagebox.showinfo("Total Spent", f"Customer {cid} has spent ₹{total:.2f}")
    log_action(f"GetCustomerTotalSpent({cid}) executed (Aggregate function)")

frame_report = ctk.CTkFrame(tab_reports)
frame_report.pack(fill="both", expand=True, padx=10, pady=10)

ctk.CTkButton(frame_report, text="Show All Orders", command=show_orders).grid(row=0, column=0, pady=10)
cid_total = ctk.IntVar()
ctk.CTkLabel(frame_report, text="Customer ID:").grid(row=1, column=0)
ctk.CTkEntry(frame_report, textvariable=cid_total).grid(row=1, column=1)
ctk.CTkButton(frame_report, text="Get Total Spent", command=total_spent).grid(row=1, column=2)

report_tree = ttk.Treeview(frame_report, columns=("OID","CustomerID","CustomerName","Item","Qty","Status","SellerID","SellerName","DeliveryID","DeliveryPartner"), show="headings")
for col in report_tree["columns"]:
    report_tree.heading(col, text=col)
    report_tree.column(col, width=100)
report_tree.grid(row=2, column=0, columnspan=5, pady=15, sticky="nsew")

app.mainloop()
