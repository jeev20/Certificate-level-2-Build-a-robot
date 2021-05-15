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
Library     RPA.Archive
# -


*** Variables ***
${websiteUrl}    https://robotsparebinindustries.com/#/robot-order
${csvUrl}   https://robotsparebinindustries.com/orders.csv
${destinationPathCSV}  input/orders.csv
${errorDivRole}   "alert"

# +
*** Keywords ***
Open Robotsparebinindustries
    Open Available Browser  ${websiteUrl} 
    
Close Modal Popup
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
    Select From List By Value    id:head    ${Head} 
    Click Button    id:id-body-${body}
    Input Text      //label[contains(.,"3. Legs")]/ ../input  ${legs}
    Input Text      id:address   ${address}
    
Preview the robot
    Wait Until Page Contains Element  css:#preview
    Execute Javascript    document.querySelector('#preview').click();
    
    
Store the receipt as a PDF file
    [Arguments]  ${orderNumber}
    Wait Until Page Contains Element  css:#receipt 
    ${robot_order}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${robot_order}    ${CURDIR}${/}output${/}${orderNumber}.pdf

Take Screeshot of Order
    [Arguments]  ${orderNumber}
    Screenshot  id:robot-preview-image  ${CURDIR}${/}output${/}${orderNumber}.png
    
Make another order
    [Arguments]  ${orderNumber}
    Wait Until Page Contains Element  css:#order-another 
    Store the receipt as a PDF file   ${orderNumber}
    Take Screeshot of Order  ${orderNumber}
    ${files}=  Create List  ${CURDIR}${/}output${/}${orderNumber}.pdf  ${CURDIR}${/}output${/}${orderNumber}.png
    Add Files To Pdf  ${files}  ${CURDIR}${/}output${/}${orderNumber}.pdf 
    RPA.FileSystem.Remove File    ${CURDIR}${/}output${/}${orderNumber}.png
    Execute Javascript    document.querySelector('#order-another').click();

Create zip file
   Archive Folder With Zip    ${CURDIR}${/}output${/}   ${CURDIR}${/}output${/}robot_orders.zip

Clean folder contents 
    [Arguments]  ${folderPath}
    ${files}=    List files in directory    ${folderPath}
    FOR    ${file}  IN  @{FILES}
        Run keyword if    "${file.name}" != "robot_orders.zip"   RPA.FileSystem.Remove File    ${file}
    END

Click Submit Button
    Wait Until Page Contains Element  css:#order
    Execute Javascript    document.querySelector('#order').click();
    #Click Button When Visible    css:#order
    Wait Until Page Contains Element  css:#order-another
        
        
Submit the order
    [Arguments]  ${orderNumber}
    Wait Until Keyword Succeeds  5x   3 sec   Click Submit Button
    Wait Until Page Contains Element  //*[@id="root"]/div/div[1]/div/div[1]/div
    ${TextErrorMessage}=  Get Element Attribute   //*[@id="root"]/div/div[1]/div/div[1]/div   Role
    Log  ${TextErrorMessage}
    IF  "${TextErrorMessage}"==${errorDivRole}
    
        Wait Until Keyword Succeeds  5x   3 sec   Click Submit Button
        Make another order  ${orderNumber}
 
    ELSE 
          Make another order  ${orderNumber}
    END
     



# +
*** Tasks ***
Order robots from RobotSpareBin Industries Inc
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
    Clean folder contents  ${CURDIR}${/}output${/} 
    
    


# -






