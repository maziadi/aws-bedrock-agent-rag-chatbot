import pandas as pd
import random

# Define sample data for each column
product_names = ["Laptop", "Smartphone", "Tablet", "Headphones", "Smartwatch", "Keyboard", "Mouse", "Monitor", "Printer", "Camera"]
types = ["Electronics", "Accessories", "Gadget", "Peripheral"]
colors = ["Black", "White", "Silver", "Red", "Blue", "Green", "Yellow", "Purple", "Pink"]
companies = ["TechCorp", "GizmoWorks", "Innovatech", "FutureGadgets", "ElectroWorld"]
sizes = ["Small", "Medium", "Large"]

# Generate the random data
data = []
for i in range(1, 31):
    product = {
        "Product Id": i,
        "Product Name": random.choice(product_names),
        "Type": random.choice(types),
        "Color": random.choice(colors),
        "Weight": round(random.uniform(0.5, 5.0), 2),  # random weight between 0.5 and 5.0
        "Size": random.choice(sizes),
        "Company": random.choice(companies),
        "Price": round(random.uniform(50, 2000), 2)  # random price between 50 and 2000
    }
    data.append(product)

# Create a DataFrame
df = pd.DataFrame(data)

# Save DataFrame to a CSV file
output_file = "products.csv"
df.to_csv(output_file, index=False)

print(f"CSV file '{output_file}' has been generated with 30 lines of product information.")

