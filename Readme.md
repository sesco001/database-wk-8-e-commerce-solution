# E-commerce Database Schema

This repository contains a **MySQL relational database schema** for a realistic **E-commerce Store**. The schema is designed with proper normalization, relationships, and constraints to ensure data integrity, scalability, and maintainability.

---

## 📌 Features
- **Users & Roles**: Customers, merchants, and admins with secure hashed passwords.
- **Products & Categories**: Full product catalog with hierarchical categories and product attributes.
- **Inventory Management**: Track stock levels, suppliers, and restocking.
- **Shopping Cart & Wishlist**: Support for carts, cart items, and user wishlists.
- **Orders & Payments**: Orders linked to users, products, addresses, and payments.
- **Discounts & Coupons**: Configurable discount codes for promotions.
- **Reviews**: Customer product reviews with ratings.
- **Addresses**: Multiple shipping and billing addresses per user.
- **Relationships**: Proper use of One-to-One, One-to-Many, and Many-to-Many relationships.

---

## 🛠️ Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/ecommerce-db.git
   cd ecommerce-db
   ```

2. Import the schema into MySQL:
   ```bash
   mysql -u root -p < ecommerce_schema.sql
   ```

3. Verify the database:
   ```sql
   SHOW DATABASES;
   USE ecommerce_db;
   SHOW TABLES;
   ```

---

## 📂 Database Structure
### Core Tables
- **users** – Stores customer and admin details.
- **addresses** – User billing/shipping addresses.
- **products** – Main product catalog.
- **categories** – Hierarchical product categories.
- **inventory** – Stock and supplier tracking.
- **orders** – Customer orders with status.
- **order_items** – Items in each order.
- **payments** – Paym
