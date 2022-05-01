*** Settings ***
Documentation   Order robots from robotsparebin industries
...             Save the receipt HTML in a pdf file
...             Take screenshot of robot and attach in pdf file
...             Zip the all reciepts
Library         RPA.Browser.Selenium
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.FileSystem
Library         RPA.HTTP
Library         RPA.Archive
Library         Dialogs
Library         RPA.Robocloud.Secrets
Library         RPA.core.notebook




***Keywords***
Open the order website
    
    ${website}=  Get Secret  websitedata
    Open Available Browser  ${website}[url]
    Maximize Browser Window


***Keywords***
Remove directory and add empty directory
    [Arguments]  ${folder}
    Remove Directory  ${folder}  True
    Create Directory  ${folder}

***Keywords***
Steps to initialize   
    Remove File  ${CURDIR}${/}orders.csv
    ${reciept_folder}=  Does Directory Exist  ${CURDIR}${/}reciepts
    ${robots_folder}=  Does Directory Exist  ${CURDIR}${/}robots
    Run Keyword If  '${reciept_folder}'=='True'  Remove directory and add empty directory  ${CURDIR}${/}reciepts  ELSE  Create Directory  ${CURDIR}${/}reciepts
    Run Keyword If  '${robots_folder}'=='True'  Remove directory and add empty directory  ${CURDIR}${/}robots  ELSE  Create Directory  ${CURDIR}${/}robots

***Keywords***
Read order file
    ${data}=  Read Table From Csv  ${CURDIR}${/}orders.csv  header=True
    Return From Keyword  ${data}

***Keywords***
Enter data for each order
    [Arguments]  ${row}
    Wait Until Page Contains Element  //button[@class="btn btn-dark"]
    Click Button  //button[@class="btn btn-dark"]
    Select From List By Value  //select[@name="head"]  ${row}[Head]
    Click Element  //input[@value="${row}[Body]"]
    Input Text  //input[@placeholder="Enter the part number for the legs"]  ${row}[Legs]
    Input Text  //input[@placeholder="Shipping address"]  ${row}[Address] 
    Click Button  //button[@id="preview"]
    Wait Until Page Contains Element  //div[@id="robot-preview-image"]
    Sleep  5 seconds
    Click Button  //button[@id="order"]
    Sleep  5 seconds

***Keywords***
Close and start the Browser before another transaction
    Close Browser
    Open the order website
    Continue For Loop


*** Keywords ***
Check if the receipt data has been processed
    FOR  ${i}  IN RANGE  ${100}
        ${alert}=  Is Element Visible  //div[@class="alert alert-danger"]  
        Run Keyword If  '${alert}'=='True'  Click Button  //button[@id="order"] 
        Exit For Loop If  '${alert}'=='False'       
    END
    
    Run Keyword If  '${alert}'=='True'  Close and start the Browser before another transaction

# +

***Keywords***
Final Receipt Processing
    [Arguments]  ${row} 
    Sleep  5 seconds
    ${reciept_data}=  Get Element Attribute  //div[@id="receipt"]  outerHTML
    Html To Pdf  ${reciept_data}  ${CURDIR}${/}reciepts${/}${row}[Order number].pdf
    Screenshot  //div[@id="robot-preview-image"]  ${CURDIR}${/}robots${/}${row}[Order number].png 
    Add Watermark Image To Pdf  ${CURDIR}${/}robots${/}${row}[Order number].png  ${CURDIR}${/}reciepts${/}${row}[Order number].pdf  ${CURDIR}${/}reciepts${/}${row}[Order number].pdf 
    Click Button  //button[@id="order-another"]

# -

***Keywords***
Processing orders
    [Arguments]  ${data}
    FOR  ${row}  IN  @{data}    
        Enter data for each order  ${row}
        Check if the receipt data has been processed 
        Final Receipt Processing  ${row}      
    END  

***Keywords***
Download csv . file
    ${file_url}=  Get Value From User  Please enter the csv file url  https://robotsparebinindustries.com/orders.csv  
    Download  ${file_url}  orders.csv
    Sleep  2 seconds

***Keywords***
Zip the receiving folder
    Archive Folder With Zip  ${CURDIR}${/}reciepts  ${OUTPUT_DIR}${/}reciepts.zip

*** Tasks ***
Bots that process orders
    Steps to initialize 
    Download csv . file
    ${data}=  Read order file
    Open the order website
    Processing orders  ${data}
    Zip the receiving folder
    [Teardown]  Close Browser


