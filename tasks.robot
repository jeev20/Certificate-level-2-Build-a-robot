# +
*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library     RPA.Browser.Selenium
Library     RPA.Tables
Library     RPA.HTTP
Library     OperatingSystem
Library     RPA.FileSystem
Library     RPA.PDF
Library     RPA.Dialogs
Library     RPA.Robocloud.Secrets
Library     RPA.Archive
Library     RPA.RobotLogListener
# -


*** Variables ***
${destinationPathCSV}  input/orders.csv
${errorDivRole}   "alert"

# +
*** Keywords ***
Get asset from vault
    [Arguments]  ${assetName}
    ${secret}=    Get Secret    vault
    [Return]  ${secret}[${assetName}]

Open Robotsparebinindustries
    # Open the website
    ${secret}=    Get Secret    vault
    ${websiteURL}=  Get asset from vault  RobotSpareBinUrl
    Open Available Browser  ${websiteURL}
    
Close Modal Popup
    # Handling the popup in the home screen
    Click Button When Visible   css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark
      
Get Orders CSV
    [Arguments]  ${csvFileURL}
    Download   ${csvFileURL}   overwrite=True   target_file=${destinationPathCSV}
    RPA.FileSystem.Wait Until Created    ${destinationPathCSV}
    File Should Exist   ${destinationPathCSV}
    ${orders}=  Read Table From Csv    ${destinationPathCSV}
    [Return]  ${orders}
    
Fill the form 
    [Arguments]  ${Head}  ${body}  ${legs}  ${address}  
    # Fills the form in the orders page
    Select From List By Value    id:head    ${Head} 
    Click Button    id:id-body-${body}
    Input Text      //label[contains(.,"3. Legs")]/ ../input  ${legs}
    Input Text      id:address   ${address}
    
Preview the robot
    # Previews the ordered robot in the home page
    Wait Until Page Contains Element  css:#preview
    Execute Javascript    document.querySelector('#preview').click();
    
    
Store the receipt as a PDF file
    [Arguments]  ${orderNumber}
    # Save the order details page as its own pdf
    Wait Until Page Contains Element  css:#receipt 
    ${robot_order}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${robot_order}    ${CURDIR}${/}output${/}${orderNumber}.pdf

Take Screeshot of Order
    [Arguments]  ${orderNumber}
    # Take the screenshot of the ordered robot
    Screenshot  id:robot-preview-image  ${CURDIR}${/}output${/}${orderNumber}.png
    
Make another order
    [Arguments]  ${orderNumber}
    # Clicks on the make another order button and also adds the screenshot to the pdf before clicking Order another robot button
    Wait Until Page Contains Element  css:#order-another 
    Store the receipt as a PDF file   ${orderNumber}
    Take Screeshot of Order  ${orderNumber}
    ${files}=  Create List  ${CURDIR}${/}output${/}${orderNumber}.pdf  ${CURDIR}${/}output${/}${orderNumber}.png
    Add Files To Pdf  ${files}  ${CURDIR}${/}output${/}${orderNumber}.pdf 
    RPA.FileSystem.Remove File    ${CURDIR}${/}output${/}${orderNumber}.png
    Execute Javascript    document.querySelector('#order-another').click();

Create zip file
    # Creates a zip file of all the .pdf in the output folder
   RPA.Archive.Archive Folder With Zip    ${CURDIR}${/}output${/}   ${CURDIR}${/}output${/}robot_orders.zip

Clean PDF files from output folder
    [Arguments]  ${folderPath}
    # Deletes the content of a given folder
    ${files}=    RPA.FileSystem.List Files In Directory   ${folderPath}
    FOR    ${file}  IN  @{FILES}
        Run keyword if    "${file.name}" != "robot_orders.zip"   RPA.FileSystem.Remove File    ${file}
    END

Reset input and output folders
    # Clear the folders for both input and output before running the robot
    ${folders}=  Create List    ${CURDIR}${/}input${/}  ${CURDIR}${/}output${/}
    FOR  ${folder}  IN  @{folders}
        ${files}=    RPA.FileSystem.List Files In Directory    ${folder}
        FOR    ${file}  IN  @{FILES}
            RPA.FileSystem.Remove File    ${file}
        END
    END 

Click Submit Button
    # Click onh te submit page when it exists
    Wait Until Page Contains Element  css:#order
    Execute Javascript    document.querySelector('#order').click();
    # Click Button When Visible    css:#order
    Wait Until Page Contains Element  css:#order-another
        
        
Submit the order
    # Look for errors in the submit page and handle the errors without stopping the process
    [Arguments]  ${orderNumber}
    Wait Until Keyword Succeeds  5x   3 sec   Click Submit Button
    Wait Until Page Contains Element  //*[@id="root"]/div/div[1]/div/div[1]/div
    ${TextErrorMessage}=  Get Element Attribute   //*[@id="root"]/div/div[1]/div/div[1]/div   Role
    Log  ${TextErrorMessage}
    IF  "${TextErrorMessage}"==${errorDivRole}
        Wait Until Keyword Succeeds  5x   3 sec  Click Submit Button
        Make another order  ${orderNumber}
    ELSE 
          Make another order  ${orderNumber}
    END
     
Input form dialog for input CSV url
    # Get user input string for the input data CSV.
    Add heading       Give me location!
    Add text input    csvURL    label=URL of csv
    ${result}=    Run dialog
    [Return]  ${result.csvURL}
    

Failure dialog
    [Arguments]  ${CorrectUrlLink}
    # Show the user that there was an error and provide the correct URL 
    Add icon      Failure
    Add heading   Robot requires the correct input URL. Run the robot again with the correct URL.
    Add text      The correct url is ${CorrectUrlLink}
    Run dialog    title=Failure
# -


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    # Reset input and output folders
    
    # Continue if user provides correct input data URL
    # Else suggest the correct url to the user through a failure dialog. 
    ${UsercsvUrl}=  Input form dialog for input CSV url
    ${csvURL}=  Get asset from vault  OrdersDataUrl
    IF  "${UsercsvUrl}" == "${csvURL}" 

        Open Robotsparebinindustries
        ${orders}=  Get Orders CSV    ${csvUrl}
        FOR  ${row}  IN  @{orders}
            Close Modal Popup
            Fill the form   ${row}[Head]  ${row}[Body]   ${row}[Legs]   ${row}[Address]
            Preview the robot
            Submit the order  ${row}[Order number]
        END

        Close Modal Popup
        Close All Browsers 
        Create zip file 
        Clean PDF files from output folder  ${CURDIR}${/}output${/} 
    
    ELSE
    Failure dialog  ${csvURL}
    END






