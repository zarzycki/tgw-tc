import pandas as pd
import sys

def get_arg(index):
    try:
        sys.argv[index]
    except IndexError:
        return ''
    else:
        return sys.argv[index]

pd.set_option('display.max_rows', None)  # None means unlimited

land_or_ocean = get_arg(1)  # 'all', 'ocn', or 'lnd'

def load_data(file_path):
    """
    Load data from a CSV file into a DataFrame.

    Args:
    file_path (str): Path to the CSV file.

    Returns:
    DataFrame: Loaded data.
    """
    return pd.read_csv(file_path)

def calculate_changes(df):
    """
    Calculate absolute and percent changes relative to the 'Historical' dataset.

    Args:
    df (DataFrame): DataFrame containing the data.

    Returns:
    DataFrame: DataFrame with additional columns for changes.
    """
    # Find the historical data
    historical_data = df[df['Dataset'] == 'Historical']

    # Join the historical data with the main DataFrame on 'Variable'
    df = df.merge(historical_data[['Variable', 'Mean']], on='Variable', suffixes=('', '_Historical'))

    # Calculate absolute change
    df['Absolute Change'] = df['Mean'] - df['Mean_Historical']

    # Calculate percent change
    df['Percent Change'] = (df['Absolute Change'] / df['Mean_Historical']) * 100

    # Remove the extra column used for calculation
    df.drop('Mean_Historical', axis=1, inplace=True)

    return df

def save_data(df, output_file):
    """
    Save the modified DataFrame to a new CSV file.

    Args:
    df (DataFrame): DataFrame to be saved.
    output_file (str): Path to the output CSV file.
    """
    df.to_csv(output_file, index=False)
    print(f"Data saved to {output_file}")

def add_sst_ratio_column(df):
    """
    Add a column calculating the ratio of percent change to absolute SST change.

    Args:
        df (pandas.DataFrame): The DataFrame containing variable change data.

    Returns:
        pandas.DataFrame: Modified DataFrame including the new 'Change Ratio to SST' column.
    """
    # Backup original order by copying the DataFrame's index to a new column
    df['original_index'] = df.index

    # Isolate SST changes
    sst_changes = df[df['Variable'] == 'xsst'][['Dataset', 'Absolute Change']].copy()
    sst_changes.rename(columns={
        'Absolute Change': 'SST Absolute Change'
    }, inplace=True)

    # Merge and maintain order by specifying sort=False
    df = df.merge(sst_changes, on='Dataset', sort=False)

    # Calculate the new column 'Change Ratio to SST'
    import numpy as np
    df['% Relative to dSST'] = np.where(df['SST Absolute Change'] != 0,
                                         df['Percent Change'] / df['SST Absolute Change'],
                                         np.nan)  # Use NaN where SST Absolute Change is 0

    # Restore the original order by sorting by the 'original_index' column
    df.sort_values('original_index', inplace=True)
    df.drop('original_index', axis=1, inplace=True)

    return df

# Example usage
if __name__ == "__main__":
    file_path = './stats/'+land_or_ocean+'/statistics_output.csv'  # Replace with your CSV file path

    data = load_data(file_path)
    data_with_changes = calculate_changes(data)
    data_with_changes = add_sst_ratio_column(data_with_changes)
    print(data_with_changes)
    save_data(data_with_changes, file_path)