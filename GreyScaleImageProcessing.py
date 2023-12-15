import cv2
import numpy as np
import csv
from sklearn.cluster import KMeans

# Load the image using OpenCV
image = cv2.imread("path/to/image.jpg")

# Convert the image to grayscale
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

# Threshold the grayscale image to obtain a binary mask
_, mask = cv2.threshold(gray, 1, 255, cv2.THRESH_BINARY)

# Find contours in the mask
contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

# Initialize empty lists for storing pixel values and corresponding categories
pixel_values = []
categories = []

# Iterate over the contours and extract pixel values for clustering
for contour in contours:
    # Compute the bounding rectangle for the contour
    x, y, w, h = cv2.boundingRect(contour)
    
    # Extract the region of interest (ROI) from the original image
    roi = image[y:y+h, x:x+w]
    
    # Flatten and append pixel values to the list
    pixel_values.extend(roi.reshape(-1, 3))
    # Initialize category as None
    categories.extend([None] * len(roi.reshape(-1, 3)))

# Convert pixel_values to a NumPy array
pixel_values = np.array(pixel_values)

# Define the number of clusters (groups)
num_clusters = 5  # Change this value as desired

# Perform K-means clustering
kmeans = KMeans(n_clusters=num_clusters, random_state=0)
kmeans.fit(pixel_values)

# Assign the cluster labels to categories
for i, label in enumerate(kmeans.labels_):
    categories[i] = label

# Create a copy of the original image for visualization
image_with_contours = image.copy()

# Loop over the contours and draw them on the image based on the categories
for contour, category in zip(contours, categories):
    # Get the contour area
    area = cv2.contourArea(contour)
    
    # Set the contour color based on the category
    if category is None:
        contour_color = (0, 0, 0)  # Black
    else:
        # Generate a unique color for each category
        np.random.seed(category)
        contour_color = tuple(np.random.randint(0, 256, 3).tolist())
    
    # Draw the contour on the image
    cv2.drawContours(image_with_contours, [contour], 0, contour_color, 2)

# Show the image with contours to the user for category selection
cv2.imshow("Image with Contours", image_with_contours)
cv2.waitKey(0)
cv2.destroyAllWindows()

# Initialize pixel count for each category
crop_count = 0
dirt_count = 0
shadow_count = 0

# Iterate over the contours and classify the categories
for contour, category in zip(contours, categories):
    # Get the contour area
    area = cv2.contourArea(contour)
    
    # Perform classification based on the selected category
    if category == 0:
        crop_count += area
    elif category == 1:
        dirt_count += area
    elif category == 2:
        shadow_count += area
    # Add more conditions for additional categories if needed

# Write the counts to a CSV file
with open("output.csv", "w", newline="") as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(["Category", "Count"])
    writer.writerow(["Crop", crop_count])
    writer.writerow(["Dirt", dirt_count])
    writer.writerow(["Shadow", shadow_count])
