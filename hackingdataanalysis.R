#Installing Libraries
install.packages("readr")
install.packages("dplyr")
install.packages("tidyverse")
install.packages("naniar")
install.packages("ggplot2")
install.packages("hexbin")  # Install the package
install.packages("corrplot")
install.packages("plotly")

#Loading Libraries
library("readr") #Reads csv files into R
library("dplyr")  #Data manipulation
library("tidyverse")
library("naniar")
library(ggplot2)
library(corrplot)
library(plotly)

#Setting the Current Working Directory
setwd("C:/Users/asus/OneDrive/Documents/AssignmentPFDA")

# ------------------------------------------------------------------------------------------------DATA IMPORT
local_file <- "hackingData.csv"
csvdata <- read_csv(local_file)
hackingdata = data.frame(csvdata)

#--------------------------------------------------------------------------------------------REMOVE DUPLICATES
nrow(hackingdata) #[212093]
hackingdata[duplicated(hackingdata) | duplicated(hackingdata, fromLast = TRUE), ]
hackingdata <- distinct(hackingdata)
nrow(hackingdata) #[211913]
hackingdata[duplicated(hackingdata) | duplicated(hackingdata, fromLast = TRUE), ] #Double Check


#-----------------------------------------------------------------------------------------------MISSING VALUES
# (ENCODING) handling missing value -------------------------------
# this shows the different categories of Encoding and the count
encoding_tbl <- table(hackingdata$Encoding)
sum(is.na(hackingdata$Encoding))  # Count NA values = 7
# shows "NULL" with 124744 occurences, treated as a string / category
# shows "N" as 1180 occurences and I suspect this is a filler for NA 

#I replaced every instance of NULL/N with “Unknown” for better readability
hackingdata$Encoding[hackingdata$Encoding %in% c("NULL", "N")] <- "Unknown"
hackingdata$Encoding <- factor(hackingdata$Encoding)

# so with categorical data, you impute using mode
# when counting mode exclude "n" and "na" or in this case "Unknown"values
valid_values <- hackingdata$Encoding[!(hackingdata$Encoding %in% c("Unknown"))]
mode_value <- names(sort(table(valid_values), decreasing = TRUE))[1]  # Get the most frequent category
hackingdata$Encoding[is.na(hackingdata$Encoding)] <- mode_value # is utf-8

# ( RANSOM ) handling missing value ------------------------------- (mean)
hackingdata$Ransom[is.na(hackingdata$Ransom)] <- mean(hackingdata$Ransom, na.rm = TRUE)
print(mean(hackingdata$Ransom, na.rm = TRUE)) #1545.643
print(median(hackingdata$Ransom, na.rm = TRUE)) #1543

# ( LOSS ) handling missing value  ---------------------------------(median)
# imputing missing values with median
hackingdata$Loss[is.na(hackingdata$Loss)] <- median(hackingdata$Loss, na.rm = TRUE)

print (median(hackingdata$Loss, na.rm = TRUE)) #1625


# EDA ------------------------------------------------------------ SALSABILA
# AQ1 (RANSOM & LOSS ) -------------------------------------------
# low (-inf - 1456), med(1456-2300), high(2300- inf)
hackingdata$ransom_category <- cut(dfdata_cleaned$Ransom, 
                                   breaks = c(-Inf, 1456, 2300, Inf),
                                   labels = c("Low", "Medium", "High"),
                                   right = FALSE)

ransom_loss_dist <- ggplot(hackingdata, aes(x = Loss, fill = ransom_category)) +
  geom_density(alpha = 0.5) +
  labs(title = "Distribution of Financial Loss for Different Ransom Categories",
       x = "Financial Loss",
       y = "Density") +
  scale_fill_manual(values = c("Low" = "lightblue", "Medium" = "lightpink", "High" = "lightgreen")) +
  theme_minimal()


# AQ2 (ENCODING & LOSS) -------------------------------------------- SALSABILA
# visualization
#1. bar plot
encoding_loss_barplot <- ggplot(hackingdata, aes(x = Encoding, y = Loss)) +
  stat_summary(fun = "mean", geom = "bar", fill = "pink", color = "black") +
  labs(title = "Average Loss by Encoding Method", 
       x = "Encoding Method", y = "Average Revenue Loss ($)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

#2. make a bar plot with Encoding_Grouped --> groups it in broader categories
hackingdata$Encoding_Grouped <- case_when(
  str_detect(hackingdata$Encoding, "windows") ~ "Windows",
  str_detect(hackingdata$Encoding, "utf") ~ "UTF",
  str_detect(hackingdata$Encoding, "iso|ISO") ~ "ISO",
  str_detect(hackingdata$Encoding, "ascii") ~ "ASCII",
  str_detect(hackingdata$Encoding, "big5|Big5") ~ "Big5",
  str_detect(hackingdata$Encoding, "EUC") ~ "EUC",
  str_detect(hackingdata$Encoding, "gb2312|GB2312") ~ "GB",
  str_detect(hackingdata$Encoding, "KOI") ~ "KOI",
  str_detect(hackingdata$Encoding, "tis|TIS") ~ "TIS",
  str_detect(hackingdata$Encoding, "shift_jis") ~ "Shift-JIS",
  str_detect(hackingdata$Encoding, "LiteSpeed") ~ "LiteSpeed",
  str_detect(hackingdata$Encoding, "Unknown") ~ "Unknown",
  TRUE ~ "Other"
)
encoding_loss_barplot2 <- ggplot(hackingdata, aes(x = Encoding_Grouped, y = Loss)) +
  stat_summary(fun = "mean", geom = "bar", fill = "pink", color = "black") +
  labs(title = "Average Loss by Encoding Method (Grouped)", 
       x = "Encoding Method (Grouped)", y = "Average Revenue Loss ($)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# AQ3 (ENCODING, RANSOM & LOSS) -------------------------------------------- SALSABILA
# this plots a heat map of ransom, encoding grouped with the financial loss as colows
ggplot(hackingdata, aes(x = Ransom, y = Encoding_Grouped)) +
  stat_summary_2d(aes(z = Loss), bins = 50) +  
  scale_fill_viridis_c(option = "plasma", direction = -1) +  
  labs(title = "Financial Loss Across Ransom Amount & Encoding Type",
       x = "Ransom Amount ($)",
       y = "Character Encoding Type",
       fill = "Avg Loss ($)") + 
  theme_minimal(base_size = 14) +  
  theme(
    axis.text.y = element_text(size = 14, face = "bold"),  
    axis.text.x = element_text(size = 12, angle = 45, hjust = 1),  
    plot.title = element_text(face = "bold", size = 18),
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 10),
    panel.grid.major = element_blank(), 
    panel.grid.minor = element_blank()) +
  scale_y_discrete(limits = rev(levels(hackingdata$Encoding_Grouped)), drop = TRUE) +
  coord_cartesian(expand = FALSE)  

# heat map 2: loss - ransom amount, top 5 encoding methods (use)
top_encodings <- hackingdata %>%
  filter(!(Encoding_Grouped %in% c("Unknown", "Other"))) %>%  # Exclude "Unknown" and "Other"
  group_by(Encoding_Grouped) %>%
  summarise(avg_loss = mean(Loss, na.rm = TRUE)) %>%
  arrange(desc(avg_loss)) %>%
  slice_head(n = 5) %>%
  pull(Encoding_Grouped)
# Filter dataset for only the top 5 encoding methods
filtered_data_bila <- hackingdata %>%
  filter(Encoding_Grouped %in% top_encodings)

# Heatmap: Ransom vs Top 5 Encoding Groups (excluding Unknown/Other), colored by Loss
ggplot(filtered_data_bila, aes(x = Ransom, y = Encoding_Grouped)) +
  stat_summary_2d(aes(z = Loss), bins = 50) +  
  scale_fill_viridis_c(option = "plasma", direction = -1) +  
  labs(title = "Financial Loss Across Ransom Amount & Top 5 Encoding Types",
       x = "Ransom Amount ($)",
       y = "Top 5 Encoding Methods",
       fill = "Avg Loss ($)") + 
  theme_minimal(base_size = 14) +
  theme(
    axis.text.y = element_text(size = 14, face = "bold"),  
    axis.text.x = element_text(size = 12, angle = 45, hjust = 1),  
    plot.title = element_text(face = "bold", size = 18),
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 10),
    panel.grid.major = element_blank(), 
    panel.grid.minor = element_blank()) +
  scale_y_discrete(limits = rev(top_encodings), drop = TRUE) +  
  coord_cartesian(expand = FALSE)

# 2.4 Boxplot: Variability of Loss across Encoding methods within each Ransom category
ggplot(hackingdata, aes(x = Encoding_Grouped, y = Loss, fill = ransom_category)) +
  geom_boxplot(outlier.shape = NA) +  # Hide outliers for better visualization
  scale_y_continuous(limits = quantile(hackingdata$Loss, c(0.05, 0.95), na.rm = TRUE)) +  # Remove extreme values
  labs(title = "Variability of Financial Loss Across Encoding Methods",
       x = "Encoding Method", y = "Financial Loss") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
