import pandas as pd

df = pd.read_csv('people_1.txt', sep = '\t')
print(len(df))

# delete white spaces in first name and last name, then convert to title case
df['FirstName'] = df['FirstName'].str.strip()
df['FirstName'] = df['FirstName'].str.title()
df['LastName'] = df['LastName'].str.strip()
df['LastName'] = df['LastName'].str.title()

# delete white spaces in email
df['Email'] = df['Email'].str.strip()

# delete '-' in phone number
df['Phone'] = df['Phone'].str.replace('-','')

def standardize_address(x):
    l_x = x.split(' ')
    l_x[0] = l_x[0].replace('No.', '')
    l_x[0] = l_x[0].replace('#', '')
    return ('No.' + ' '.join(l_x))

# standarize numbers in address to 'No.xxxx' format
df['Address'] = df['Address'].apply(lambda x: standardize_address(x))

# drop duplicates and reset index
df = df.drop_duplicates()
df.reset_index(drop = True, inplace = True)

df.to_csv('people_1.csv', index = False)




