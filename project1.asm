################################################################# Data ##############################################################
.data
    # Define variables and constants here
    fileName: .asciiz "C:\\Users\\atoz\\Desktop\\project\\tests.txt"
    fileWords: .space 32         # Will hold the whole file data
    buffer: .space 32            # Will hold only a line
    headNode : .space 4          # Head node for the linked list
    # Constants for conversion to float
    constant : .float 10.0
    fraction : .float 0.1
    base : .float 0.0
    # Valid test names
    valid_test_names: .asciiz "Hgb BGT LDL BPT"
    test_names: .asciiz "Hgb \0 BGT \0 LDL \0 BPT "
    
       
    # Valid year and months for add new test
    valid_years: .asciiz "2024"
    valid_months: .asciiz "01 02 03 04 05 06 07 08 09 10 11 12"
    num_valid_months: .word 12
 
    HGB_MIN: .float 13.0
    HGB_MAX: .float 17.2
    BGT_MIN:.float 70.0
    BGT_MAX: .float 99.0
    LDL_MAX: .float 100.0
    SBP_MAX: .float 120.0
    DBP_MAX: .float 80.0
   
    test_name: .space 4
   
#-----------------------------------------------------    
             
# Define a macro for printing
.macro display(%str)    
        .data
label: .asciiz %str
         .text
         li $v0, 4
         la $a0, label
         syscall
         .end_macro    
  
################################################################# Code ##############################################################
.text
.globl main
main:
    la $t0,headNode              # Indicates to the beginning of the empty linked list, the linked list will hold tetst, one node for each test
    li $t1, 0
    sw $t1, 0($t0)               # initially head node is poiting to null(zero)            [0]
    la $t2, buffer               # Load address of buffer which is a buffer that will keep one line of the file before storing it proberly
                                 # t2 will have the array that contains information about a single test
   
    # Open file
    li $v0, 13                   # Open file syscall is 13
    la $a0, fileName             # Get the file name
    li $a1, 0                    # File flag, 0 for read
    li $a2, 0                    # Mode is ignored
    syscall
    move $s0, $v0                # Save the file descriptor , $s0 = file
   
   
    blt $s0,$zero, whileloop     # File descriptor is negative if error
   
   
 read_loop:      
    # Read from file
    li $v0, 14                   # Read file syscall is 14
    move $a0, $s0                # File descriptor to identify which file to read
    la $a1, fileWords            # Address of input buffer that holds the whole file
    li $a2, 1                    # Maximum number of characters to read, we are going to read character by character
    syscall
   
    # Check for end of file
    beq $v0, $zero, close        # Close the file if $v0 = 0
   
    # Check for newline
    lb $t0, 0($a1)               # Load the byte read
    beq $t0, 10, new_line        # Check if it's a newline character '\N'
   
    # Print the character
    li $v0, 11                   # Print character syscall is 11
    move $a0, $t0                # Character to print
    syscall
   
    # Store the byte into the current array
    sb $t0, ($t2)               # Store byte into the current array
    addi $t2, $t2, 1            # Move to the next byte in the array
   
    j read_loop                 # Continue reading
   
    # Print new line character
 new_line:
    li $v0, 11                  # Print character syscall is 11
    li $a0, 10                  # ASCII code for newline character
    syscall
    
    la $t2, buffer              # t2 now is pointing to the first char in the line (new array for the new test in the next line)
    jal store_in_array_from_file # After finishing reading a complete test, store it in the array
    j read_loop                 # Continue reading
   
 close:    
    # Close the file
    li $v0, 16                  # Close file syscall is 16
    move $a0, $s0               # File descriptor to close
    syscall
#finished reading from file 
#now will show the main menu to choose from

 whileloop:
    # Display menu
    display("\n \n Choose an operation:\n")
    display("1- Add new medical test.\n")
    display("2- Search for a test by patient ID.\n")
    display("3- Serch for unnormal tests.\n")
    display("4- Average test value.\n")
    display("5- Update test result.\n")
    display("6- Delete test.\n")
    display("7- Print all and exit.\n")
   
    # Read from user then branch to the suitable case
    li $v0, 5            # Read integer syscall is 5
    syscall
    move $t0, $v0        # Store user choice in $t0
   
    # Process operations by functions, based on user's choice
    beq $t0,1,add_new_test
    beq $t0,2,search_test
    beq $t0,3,abnormal_tests_search
    beq $t0,4,average_test_value
    beq $t0,5,update_test_result
    beq $t0,6,delete_test
    beq $t0,7,print_all_and_exit
    display("invalid input...\n")
    j whileloop
 
 print_all_and_exit:
    jal print_all
    # Clean up and exit
    li $v0, 10  # Exit syscall
    syscall

##################################################################### Functions #############################################################
# This function takes the string stored in buffer and then store it proberly
store_in_array_from_file:
    # This part of the code is used to allocate 28 bytes from the memory to store the test info
    li $v0,9   # Syscall to allocate memory
    li $a0,28 # [ID,Test,YY,MM,RES1,RES2 , address for the next node]
    syscall                     # $v0 contains the address for the initialized node    
    move $t3,$v0 # The address of the initialized node is now stored in $t3
   
    # Convert the ID to an int and store it
    la $a3, buffer
    la $t7,string2integer
    jalr $t8,$t7                # The int is now at $v1
    sw $v1,0($t3)
   
    # Copy the test name
    addiu $a3,$a3,2             # Pointing to the name of the test [1300500: RBC] pointing on R (increment the address in $a3 by 2)
    addiu $t3,$t3,4             # [ID,] increment the register by 4 to keep space for the test name
    lb $t7,0($a3)               # $a3 now points to the first character of the test name
    
       
 # Copy the test name from the buffer to the allocated memory block
 copy:
    sb $t7,0($t3)
    addiu $a3,$a3,1            # Move to the next byte in the buffer
    addiu $t3,$t3,1            # Move to the next byte in the memory block
    lb $t7,0($a3)
    bne $t7,',', copy          # Continue if the next character is not a comma
    addiu $a3,$a3,2            # Skip the comma and space
   
    # Convert the year into an int
    la $t7,string2integer
    jalr $t8,$t7                # The int is now at $v1
    sw $v1,1($t3)
    addiu $a3,$a3,1             # Skip the -
   
    # Convert the month into an int
    la $t7,string2integer
    jalr $t8,$t7                # The int is now at $v1
    sw $v1,5($t3)
    addiu $a3,$a3,2
    addi $t3,$t3,9
   
    # Convert the result into a float
    la $t7,string2float
    jalr $t8,$t7 # Res1 is stored at $f0
    swc1 $f0, 0($t3)
   
    # Check if there is res2 and convert it to float then store it
    addi $t3,$t3,4 # Move to Res 2
   
    la $t8,0($v0)
    addiu $t8,$t8,4
    lb $t7,0($t8) # Load the character read into $t7
    bne $t7,'B' ,next
    addiu $t8,$t8,1 # Move to the next character
    lb $t7,0($t8)
    bne $t7,'P' ,next
    addiu $t8,$t8,1
    lb $t7,0($t8)
    bne $t7,'T' ,next
    addiu $a3,$a3,2 # Increment the address in register $a3 by 2 bytes to move to the next part of the data in the buffer
    la $t7,string2float # Convert the second result into float
    jalr $t8,$t7 # Res is stored at $f0
    swc1 $f0, 0($t3) # Store the second result in the memory block pointed to by register $t3
   
 # Continue processing if there is no second result  
 next:
    addi $t3,$t3,-20  # Pointing to the bigining of the node (beginning of the memory block)
    
    la $t7,headNode   # Pointing to the head node
    lw $t8,0($t7)     # Load the value stored at the address pointed to by $t7 into register $t8 (the old head node)
    sw $t8,24($t3)    # Store the old head node's address in the memory block pointed to by register $t3 (the next node pointer)
    sw $t3,0($t7)     # Store the address of the new node (stored in register $t3) in headNode, making it the new head node.
   
    jr $ra
#----------------------------------------------------------------------------------------------------
# This function takes the string stored in $a3 and convert it to an integer and store it in $v1
string2integer:
    li $v1, 0                  # Initialize: $v1 = sum = 0
    li $t5, 10                 # Base for decimal conversion
L1:
    lb $t6, 0($a3)             # Load character from the string
    beqz $t6, done             # Exit loop if null character encountered
    blt $t6, '0', done         # Exit loop if character is not numeric
    bgt $t6, '9', done         # Exit loop if character is not numeric
    addiu $t6, $t6, -48        # Convert ASCII to integer value
    mul $v1, $v1, $t5          # Multiply current sum by 10
    addu $v1, $v1, $t6         # Add current digit to sum
    addiu $a3, $a3, 1          # Move to the next character
    j L1
done:
    jr $t8                     # Return to the caller the ineger is stored in $v1
 
#----------------------------------------------------------------------------------------------------
# This function takes the string stored in $a3 and convert it to a float and store it in $f0  
string2float:  
    # Address of the bigining of the string is in $a3
    l.s $f1, constant          # Load constant 10.0 into $f1
    l.s $f2, fraction          # Load fraction 0.1 into $f2
    lwc1 $f0, base             # Initialize result to 0.0
    # Loop for integer part  
L2:
    lb $t6, 0($a3)             # Load character from the string
    beqz $t6, done2            # Exit loop if null character encountered
    beq $t6, 46, fraction_part # Exit loop if decimal point encountered
    beqz $t6, done3
    blt $t6, '0', done3       # Exit loop if character is not numeric
    bgt $t6, '9', done3        # Exit loop if character is not numeric
    addiu $t6, $t6, -48        # Convert ASCII to integer value
    mtc1 $t6, $f6              # Move integer value to floating-point register
    cvt.s.w $f3, $f6           # Convert integer to floating point
    mul.s $f0, $f0, $f1        # Multiply current result by 10
    add.s $f0, $f0, $f3        # Add current digit to result
    addiu $a3, $a3, 1
    j L2
# Loop for fractional part
fraction_part:
    addiu $a3, $a3, 1          # Move to the next character  (now we're pointing to the decimal point)
    lwc1 $f3, base             # Initialize fractional part to 0.0
L3:
    lb $t6, 0($a3)             # Load character from the string
    beqz $t6, done2            # Exit loop if null character encountered
    beq $t6, 46, done2         # Exit loop if decimal point encountered
    blt $t6, '0', done2        # Exit loop if character is not numeric
    bgt $t6, '9', done2        # Exit loop if character is not numeric
    addiu $t6, $t6, -48        # Convert ASCII to integer value
    mtc1 $t6, $f6              # Move integer value to floating-point register
    cvt.s.w $f4, $f6           # Convert integer to floating point
    mul.s $f4, $f4, $f2        # Multiply current fractional part by 0.1
    add.s $f3, $f3, $f4        # Add current digit to fractional part
    addiu $a3, $a3, 1          # Move to the next character
    j L3
done2:
    add.s $f0, $f0, $f3        # Add fractional part to result
done3:
    jr $t8                     # Return to the caller
    
#----------------------------------------------------------------------------------------------------

# Function to add new test
add_new_test:
    # Prompt the user to enter values
    display("Enter values for the new test [Patient ID, Test Name, Date(YY-MM), Result].\n")
    # Allocate memory for the patient ID
   
     li $v0, 9               # Syscall to allocate memory
    li $a0, 28              # Allocate 28 bytes for the patient node
    syscall
    move $s1,$v0            # $s1 contains the address of the new node 
    
# Read patient ID as a string
read_patient_id:
    display("\nEnter the patient ID:\n")
    li $v0, 8
    la $a0, buffer
    li $a1, 8               # Maximum length of patient ID 7 digits + null terminator
    syscall
    
    # Count digits in patient ID
    la $t0, buffer      # Load the address of the buffer
    li $t1, 0           # Initialize digit counter

count_digits_loop:
    lb $t2, 0($t0)          # Load the current character from buffer
    beqz $t2, check_length  # Exit loop if the current character is null
    blt $t2, '0', invalid_patient_id  # If the character is less than '0', it's invalid
    bgt $t2, '9', invalid_patient_id  # If the character is greater than '9', it's invalid
    addi $t1, $t1, 1        # Increment the digit counter
    addi $t0, $t0, 1        # Move to the next character in buffer
    j count_digits_loop     # Repeat until reaching null character
    
# Check length of patient ID
check_length:
    bne $t1, 7, invalid_patient_id  # If the number of digits is not 7, it's invalid
        
# If the patient ID is valid, continue processing
valid_patient_id:
    # Convert the ID to an int and store it 
    la $a3, buffer
    la $t7,string2integer
    jalr $t8,$t7                # The int is now at $v1
    
    sw $v1, 0($s1)
    j read_test_name

# Invalid patient ID
invalid_patient_id:
    display("\nInvalid patient ID. Please re-enter a valid value.\n")
    j read_patient_id     

#--------
# Read test name and check its validity
read_test_name:
    display("\nEnter the test name:\n")
    li $v0, 8
    la $a0, buffer
    li $a1, 4   # Maximum length of test name
    syscall    
    # We only have 4 valid test names (Hgb, BGT, LDL, BPT) if not any then invalid 
    #in the code below we compare each char with the valid once to determine if the user input test is valid
    la $t3 , buffer
    lb $t4, 0($t3)
    beq $t4 ,'H', valid_H                
    beq $t4 ,'L', valid_L
    bne $t4 ,'B', invalid_test_name
    lb $t4, 1($t3)
    beq $t4,'G', valid_BG
    beq $t4,'P', valid_BP
    j invalid_test_name
    
  valid_H:
    lb $t4, 1($t3)
    bne $t4 ,'g', invalid_test_name
    lb $t4, 2($t3)
    bne $t4 ,'b', invalid_test_name
    j valid_test_name
  valid_L:
    lb $t4, 1($t3)
    bne $t4 ,'D', invalid_test_name
    lb $t4, 2($t3)
    bne $t4 ,'L', invalid_test_name
    j valid_test_name
    
   valid_BG:
    lb $t4, 2($t3)
    bne $t4 ,'T', invalid_test_name
    j valid_test_name
    
   valid_BP:
    lb $t4, 2($t3)
    bne $t4 ,'T', invalid_test_name
    j valid_test_name
      
  invalid_test_name:
     display("\nInvalid test name. Please re-enter a valid name.\n")
     j read_test_name
    
  valid_test_name:

     # Copy the test name to the allocated memory
      la $t3, 4($s1)          # Load the address of the allocated memory into $t3
      la $t4, buffer          # Load the address of the buffer into $t4
     copy_test_name:
      lb $t5, 0($t4)          # Load the current character from buffer
      sb $t5, 0($t3)          # Store the current character to allocated memory
      addi $t3, $t3, 1        # Move to the next byte in the allocated memory
      addi $t4, $t4, 1        # Move to the next byte in the buffer
      bnez $t5, copy_test_name    # Repeat until reaching null character  
     j read_date

#----------
# Read the date entered and check its validity
read_date:
    display("\nEnter date..\nEnter year:\n")
    li $v0, 5               # Read integer
    syscall
    move $t0, $v0           # Move the entered year to $t0

    # Check the validity of the entered year
    beq $t0, 2024, valid_year    # If the entered year matches the valid year, proceed
    j invalid_year

valid_year:
    sw $t0, 8($s1)          # Store the entered year
   
read_month:    
    display("\nEnter month:\n") 
    li $v0, 5
    la $a0, buffer
    syscall
    
    # Parse month from date
    move $t6, $v0          # Load the entered month from buffer
    blt $t6, 0, invalid_month # If the entered month is less than 0, it's invalid
    bge $t6, 13, invalid_month  # If the entered month is greater than or equal to 13, it's invalid
    # If valid, store
    sw $t6, 12($s1)
    j read_result

# Invalid year
invalid_year:
    display("\nInvalid year. Please re-enter a valid year.\n")
    j read_date
    
# Invalid month
invalid_month:
    display("\nInvalid month. Please re-enter a valid month.\n")
    j read_month


#--------
# Read the result
read_result:
    display("\nEnter result:\n")               
    # Read the result
    li $v0, 6
    syscall
    
    swc1 $f0, 16($s1)
     
    # Check if the test name is BPT, if yes, ask the user to enter a second result
    lb $t1, 5($s1)
    beq $t1,'P', enter_second_result    

    display("\nTest has been added successfully!\n")
    j handleNextPointer
    
enter_second_result:        
    display("\nEnter second result:\n") 
    # Read the result
    li $v0, 6
    syscall

    # Store
    swc1 $f0, 20($s1)
    
    
#--------------
# Handle next pointer
handleNextPointer:
    # we already now that the address of the new node is stored in  s1 
    la $t4, headNode
    lw $t5,0($t4)
    sw $t5,24($s1)
    sw $s1,0($t4)
    j whileloop
    
#-----------------------------------------------------------------------------------------------------------------
#search based on user ID
search_test:
   display("please enter the ID of the patient you're searching for:\n")
   li $v0, 5                                #system call to read an integer
   syscall
   move $s0, $v0                            #store the ID in $s0
   display("1- Retrieve all patient tests\n")
   display("2- Retrieve all up normal patient tests\n")
   display("3-Retrieve all patient tests in a given specific period \n")
   display("please select what do you want to retrieve: \n")
   
   li $v0, 5                                #system call to read an integer
   syscall
   move $t0, $v0                            #we'll decide the operation based on the number stored in $t0
   la $a1,headNode                          #point to the head node (this node contains the address for the first patient)
   lw $a2,0($a1)                            #$a1 now contains the adress of the first patient
   
   display("searching if there is any matching info .....\n")
   beq $t0, 1, all_tests
   beq $t0, 2, abnormal
   beq $t0, 3, period
   display("there's no such operation\n")
   j terminate
   
 all_tests:
   beq $zero, $a2, terminate                #if the next address is not null move to it            
   lw $t0,0($a2)     # t0 contains the ID of the patients in the linked list
   move $a3,$a2
   addiu $a2, $a2,24                        #$a2 points to the next address
   lw $a2,0($a2)                            #$a2 has the next address (pointing to the next ID)
   bne $s0, $t0, all_tests
   la $t7,print_data                        #to use jump and link reg
   jalr $t8,$t7                             #current link is stored in $t8
   j  all_tests
     
 abnormal:
   beq $zero, $a2, terminate
   lw $t0,0($a2)
   move $a3,$a2
   addiu $a2, $a2,24
   lw $a2,0($a2)
   bne $s0, $t0,abnormal                  
   #im not reading new data from the user and im searching in the file which is surely valid thus I can decide the case onle by the first letter
   #for Hgb and LDL and the sec one for the rest
   lb $t1,4($a3)                          #load the first letter in the test name
   lwc1 $f0,16($a3)                       #pre-load the float (so I dont have to repeat it in every case)                
   beq $t1,'H',Hgb                        #initially if the first letter is H go to the Hgb test
   beq $t1,'L',LDL                        #same for LDL
   lb $t1,5($a3)                          #load the sec letter to decide              
   beq $t1,'G',BGT
   j BPT
 
 Hgb:
   l.s $f1,HGB_MIN
   l.s $f2,HGB_MAX
   c.lt.s $f0,$f1
   bc1t print_apnormal
   c.lt.s $f2,$f0
   bc1t print_apnormal
   j abnormal
   
 BGT:
   l.s $f1,BGT_MIN
   l.s $f2,BGT_MAX
   c.lt.s $f0,$f1
   bc1t print_apnormal
   c.lt.s $f2,$f0
   bc1t print_apnormal
   j abnormal
   
 LDL:
   l.s $f2,LDL_MAX
   c.lt.s $f2,$f0
   bc1t print_apnormal
   j abnormal

 BPT:
   l.s $f2,SBP_MAX
   c.lt.s $f2,$f0
   bc1t print_apnormal
   lwc1 $f0,20($a3)
   l.s $f2,DBP_MAX
   c.lt.s $f2,$f0
   bc1t print_apnormal
   j abnormal
   
 print_apnormal:
   la $t7,print_data
   jalr $t8,$t7                             #current link is stored in $t8
   j  abnormal
 
 period:  
   display("Please enter the starting year : ")
   li $v0, 5                                #system call to read an integer
   syscall
   move $t1,$v0
   display("Please enter the starting month: ")
   li $v0, 5                                #system call to read an integer
   syscall
   move $t2,$v0
   display("Please enter the ending year : ")
   li $v0, 5                                #system call to read an integer
   syscall
   move $t3,$v0
   display("Please enter the ending month: ")
   li $v0, 5                                #system call to read an integer
   syscall
   move $t4,$v0
   
   #check if the input data is valid
   display("checking the validity ... \n")
   blt $t1,1950,terminate                                                   #valid dates : 1950 - 2024
   bgt $t1,2024,terminate                                                  
   bgt $t3,2024,terminate
   blt $t3,$t1,terminate
   
   blt $t2,1,terminate
   blt $t4,1,terminate
   bgt $t2,12,terminate
   bgt $t4,12,terminate
   
   bne $t3,$t1,period_checking                                              #if starting year != ending year then data is valid
   li $t5,1                                                                 #I'll use this as a flag to remmember this case
   blt $t4,$t2,terminate
   
 period_checking:  
   beq $zero, $a2, terminate
   lw $t0,0($a2)
   move $a3,$a2
   addiu $a2, $a2,24
   lw $a2,0($a2)
   bne $s0, $t0,  period_checking
   
   #start checking the periods
   lw $t6, 8($a3) #year
   lw $t7, 12($a3) #month
   beq $t1, $t3,starting_year_equals_ending_year
   beq $t6, $t1, year_equals_starting_year
   beq $t6, $t3, year_equals_ending_year
   blt $t6, $t1, period_checking                                     # year < starting year
   bgt $t6, $t3, period_checking                                     #year > ending year
   j print_period
   
 year_equals_starting_year:
   blt $t7,$t2, period_checking
   j print_period
 year_equals_ending_year:  
   bgt $t7,$t4, period_checking
   j print_period
 starting_year_equals_ending_year:
   bne $t6,$t1, period_checking
   blt $t7,$t2, period_checking
   bgt $t7,$t4, period_checking
   j print_period
   
 print_period:
   la $t7,print_data
   jalr $t8,$t7                             #current link is stored in $t8
   j  period_checking
   
#-----------------------------------------------------------------------------------------------------------------
#search based on the test name
abnormal_tests_search:
   display ("please enter medical test to retrieve its data:\n")
   li $v0, 8         # syscall code for read_string
   la $a0, test_name    
   li $a1, 4        
   syscall
   display("\nsearching for matches... \n")
   la $a1,headNode                          #point to the head node (this node contains the address for the first patient)
   lw $a2,0($a1)                            #$a1 now contains the adress of the first patient
   la $a1,test_name
   lb $t0,0($a1)
   beq $t0,'H',H
   beq $t0,'L',L
   bne $t0,'B',terminate
   lb $t0,1($a1)
   beq $t0,'G',BG
   beq $t0,'P',BP
   j whileloop
 H:
    lb $t0,1($a1)
    bne $t0,'g',terminate
    lb $t0,2($a1)
    bne $t0,'b',terminate                    # now we're sure that the user entered Hgb
 test_Hgb:  
    beq $zero, $a2, terminate                #if the next address is not null move to it            
    lb $t0,4($a2)                            # t0 contains first letter of the patient's name in the linked list
    move $a3,$a2
    addiu $a2, $a2,24                        #$a2 points to the next address
    lw $a2,0($a2)                            #$a2 has the next address (pointing to the next ID)
    bne $t0,'H' ,test_Hgb
    lwc1 $f0,16($a3)
    l.s $f1,HGB_MIN
    l.s $f2,HGB_MAX
    c.lt.s $f0,$f1
    bc1t print_H
    c.lt.s $f2,$f0
    bc1t print_H
    j test_Hgb
 print_H:
    lw $t0,0($a3)
    la $t7,print_data                        #to use jump and link reg
    jalr $t8,$t7                             #current link is stored in $t8
    j  test_Hgb  
 L:
    lb $t0,1($a1)
    bne $t0,'D',terminate
    lb $t0,2($a1)
    bne $t0,'L',terminate  
  test_LDL:  
    beq $zero, $a2, terminate                #if the next address is not null move to it            
    lb $t0,4($a2)      # t0 contains first letter of the patient's name in the linked list
    move $a3,$a2
    addiu $a2, $a2,24                        #$a2 points to the next address
    lw $a2,0($a2)                            #$a2 has the next address (pointing to the next ID)
    bne $t0,'L' ,test_LDL
    lwc1 $f0,16($a3)
    l.s $f2,LDL_MAX
    c.lt.s $f2,$f0
    bc1t print_L
    j test_LDL
  print_L:  
    lw $t0,0($a3)
    la $t7,print_data                        #to use jump and link reg
    jalr $t8,$t7                             #current link is stored in $t8
    j  test_LDL  
   
 BG:
   lb $t0,2($a1)
   bne $t0,'T',terminate  
 Test_BGT:
    beq $zero, $a2, terminate                #if the next address is not null move to it            
    lb $t0,5($a2)      # t0 contains first letter of the patient's name in the linked list
    move $a3,$a2
    addiu $a2, $a2,24                        #$a2 points to the next address
    lw $a2,0($a2)                            #$a2 has the next address (pointing to the next ID)
    bne $t0,'G' ,Test_BGT
    lwc1 $f0,16($a3)
    l.s $f1,BGT_MIN
    l.s $f2,BGT_MAX
    c.lt.s $f0,$f1
    bc1t print_BG
    c.lt.s $f2,$f0
    bc1t print_BG
    j Test_BGT
 print_BG:
    lw $t0,0($a3)
    la $t7,print_data                        #to use jump and link reg
    jalr $t8,$t7                             #current link is stored in $t8
    j Test_BGT  
   
 BP:
   lb $t0,2($a1)
   bne $t0,'T',terminate
 Test_BPT:  
    beq $zero, $a2, terminate                #if the next address is not null move to it            
    lb $t0,5($a2)      # t0 contains first letter of the patient's name in the linked list
    move $a3,$a2
    addiu $a2, $a2,24                        #$a2 points to the next address
    lw $a2,0($a2)                            #$a2 has the next address (pointing to the next ID)
    bne $t0,'P' ,Test_BPT
    lwc1 $f0,16($a3)
    l.s $f2,SBP_MAX
    c.lt.s $f2,$f0
    bc1t  print_BP
    lwc1 $f0,20($a3)
    l.s $f2,DBP_MAX
    c.lt.s $f2,$f0
    bc1t  print_BP
    j Test_BPT
   
 print_BP:
    lw $t0,0($a3)
    la $t7,print_data                        #to use jump and link reg
    jalr $t8,$t7                             #current link is stored in $t8
    j Test_BPT

#-----------------------------------------------------------------------------------------------------------------
#this function prints the avg value of each test 
average_test_value:
    #here we'll check the second char to detrmine the test type
    la $a1,headNode                          #point to the head node (this node contains the address for the first patient)
    lw $a2,0($a1)                            #$a1 now contains the adress of the first patient
   
    li $t3,0
    li $t4,0
    li $t5,0
    li $t6,0
   
    lwc1 $f0, base                         #base = 0.0
    lwc1 $f1, base
    lwc1 $f2, base
    lwc1 $f3, base
    lwc1 $f4, base
  
 avg_loop:
 
   beq $zero, $a2, divide_and_print         #if the next address is not null move to it            
   lb $t0,5($a2)                            # t0 contains the second letter of the test name in the linked list   LGL Hgb BPT BGT
   move $a3,$a2                             #$a3=$a2
   addiu $a2, $a2,24                        #$a2 points to the next address
   lw $a2,0($a2)                            #$a2 has the next address

   beq $t0,'D', sum_LDL
   beq $t0,'g', sum_Hgb
   beq $t0,'G', sum_BGT
   beq $t0,'P', sum_BPT
                                           
 sum_LDL:
   addi $t3,$t3,1                       #sum(res)/patients#
   lwc1 $f5, 16($a3)
   add.s $f0,$f0,$f5
   j avg_loop
   
 sum_Hgb:
   addi $t4,$t4,1
   lwc1 $f5, 16($a3)
   add.s $f1,$f1,$f5
   j avg_loop
   
 sum_BGT:
   addi $t5,$t5,1
   lwc1 $f5, 16($a3)
   add.s $f2,$f2,$f5
   j avg_loop
   
 sum_BPT:
 
   addi $t6,$t6,1
   lwc1 $f5, 16($a3)
   add.s $f3,$f3,$f5
   
   lwc1 $f5, 20($a3)
   add.s $f4,$f4,$f5
    j avg_loop
                                               
 divide_and_print:
 
   la $a1,test_names
   li $v0, 4                   #print test name (Hgb)
   la $a0,0($a1)
   syscall
   
   lwc1 $f12, base             #to handle divide by zero case
   beqz $t4, print_HGB_AVG
   
   mtc1 $t4, $f5
   cvt.s.w $f5,$f5
   div.s $f1,$f1,$f5
   mov.s $f12,$f1

 print_HGB_AVG:
   li $v0, 2                   #syscall to print float   
   syscall
#-------------
   li $v0, 4                   #print test name (BGT)
   la $a0,5($a1)
   syscall
   
   lwc1 $f12, base
   beqz $t5, print_BGT_AVG
   
   mtc1 $t5, $f5
   cvt.s.w $f5,$f5
   div.s $f2,$f2,$f5
   mov.s $f12,$f2
   
 print_BGT_AVG:
   li $v0, 2                   #syscall to print float  
   syscall
#-------------
   
   li $v0, 4                   #print test name (LDL)
   la $a0,11($a1)
   syscall
   
   lwc1 $f12, base
   beqz $t3, print_LDL_AVG
   
   mtc1 $t3, $f5
   cvt.s.w $f5,$f5
   div.s $f0,$f0,$f5
   mov.s $f12,$f0
 
 print_LDL_AVG:
   li $v0, 2                   #syscall to print float  
   syscall
#-------------
   li $v0, 4                   #print test name (LDL)
   la $a0,17($a1)
   syscall
   
   lwc1 $f12, base
   beqz $t6, print_BPT_AVG
   
   mtc1 $t6, $f5
   cvt.s.w $f5,$f5
   div.s $f3,$f3,$f5
   mov.s $f12,$f3
   div.s $f4,$f4,$f5 
   
   print_BPT_AVG:
   li $v0, 2                   #syscall to print float  
   syscall
   
   beqz $t6, terminate
  
   li $v0, 11                  # Print character syscall is 11
   li $a0, ' '                 # print the space
   syscall
   
   mov.s $f12,$f4
   li $v0, 2                   #syscall to print float  
   syscall
   
   j terminate

#-----------------------------------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------------------------------
# Function to update test result
update_test_result:
    # Prompt the user to enter the patient ID and test name
    display("Enter patient ID to update test result:\n")
    li $v0, 5
    syscall
    move $s0, $v0                            # Store patient ID
    li $t9, 0 
    
    # show all tests of the patient 
    la $a1,headNode                          #point to the head node (this node contains the address for the first patient)
    lw $a2,0($a1)                            #$a1 now contains the adress of the first patient
    show_all_tests:
    
    	 beq $zero, $a2, printed                #if the next address is not null move to it            
   	 lw $t0,0($a2)                          # t0 contains the ID of the patients in the linked list
  	 move $a3,$a2
  	 lw $a2,24($a2)                            #$a2 has the next address (pointing to the next ID)
  	 bne $s0, $t0, show_all_tests
  	 addi $t9,$t9,1
  	 
  	 li $v0, 1                   #syscall to print integer
  	 move $a0,$t9                #print patient ID
 	 syscall
 
 	 li $v0, 11                  # Print character syscall is 11
 	 li $a0, '-'                 #print :b
  	 syscall
  	 
  	 la $t7,print_data                        #to use jump and link reg
 	 jalr $t8,$t7                             #current link is stored in $t8
  	 j  show_all_tests
  	 	 
    printed:
    	beqz $t9,not_found
    	display("Enter test number:\n")   
        li $v0, 5
        syscall  
        move $s1, $v0         # Store test number
        
        bgt $s1, $t9, not_found
        la $a1,headNode
        lw $a2,0($a1)                            #$a1 now contains the adress of the first patient
        li $t9, 0
        
   search_for_test_to_update:
   	 beq $zero, $a2, not_found                #if the next address is not null move to it            
   	 lw $t0,0($a2)                            # t0 contains the ID of the patients in the linked list
  	 move $a3,$a2
  	 lw $a2,24($a2)                           #$a2 has the next address (pointing to the next ID)
  	 bne $s0, $t0, search_for_test_to_update
  	 addi $t9,$t9,1
  	 bne $s1,$t9, search_for_test_to_update
  	 
  	 display("Enter the new result\n")
  	 li $v0, 6
  	 syscall                                #new res is stored in $f0
  	 swc1 $f0, 16($a3)
  	 
  	 lb $t9, 5($a3)
  	 bne $t9,'P', done_update
  	 
  	 display("Enter the second result\n")
  	 li $v0, 6
  	 syscall                                #new res is stored in $f0
  	 swc1 $f0, 20($a3)
  	 
  	 j done_update
  	 
    not_found:
        display("\nPatient ID or test name not found.\n")
        j whileloop
   
    done_update:
        display("\nUpdate completed.\n")
        j whileloop  # Return to the main menu
        
#-----------------------------------------------------------------------------------------------------------------
delete_test:

# Prompt the user to enter the patient ID and test name
    display("Enter patient ID to delete test:\n")
    li $v0, 5
    syscall
    move $s0, $v0         # Store patient ID
    li $t9, 0
    # show all tests of the patient 
    la $a1,headNode                          #point to the head node (this node contains the address for the first patient)
    lw $a2,0($a1)                            #$a1 now contains the adress of the first patient
    
    show_all_tests_to_delete:
    
    	 beq $zero, $a2, printed_delete                #if the next address is not null move to it            
   	 lw $t0,0($a2)                          # t0 contains the ID of the patients in the linked list
  	 move $a3,$a2
  	 lw $a2,24($a2)                            #$a2 has the next address (pointing to the next ID)
  	 bne $s0, $t0, show_all_tests_to_delete
  	 addi $t9,$t9,1
  	 
  	 li $v0, 1                   #syscall to print integer
  	 move $a0,$t9                #print patient ID
 	 syscall
 
 	 li $v0, 11                  # Print character syscall is 11
 	 li $a0, '-'                 #print :b
  	 syscall
  	 
  	 la $t7,print_data                        #to use jump and link reg
 	 jalr $t8,$t7                             #current link is stored in $t8
  	 j  show_all_tests_to_delete
  	 	 
    printed_delete:
    	beqz $t9,not_found
    	display("Enter test number:\n")   
        
        li $v0, 5
        syscall  
        move $s1, $v0         # Store test number
        
        bgt $s1, $t9, not_found
        
        la $a1,headNode
        lw $a2,0($a1)                            #$a1 now contains the adress of the first patient
        la $a3,headNode
        li $t9, 0
        search_for_test_to_delete:
        
         move $a1, $a3                             # this will be a pointer to the previous node
   	 beq $zero, $a2, not_found                #if the next address is not null move to it            
   	 lw $t0,0($a2)                            # t0 contains the ID of the patients in the linked list
  	 move $a3,$a2
  	 lw $a2,24($a2)                           #$a2 has the next address (pointing to the next ID)
  	 bne $s0, $t0, search_for_test_to_delete
  	 addi $t9,$t9,1
  	 bne $s1,$t9, search_for_test_to_delete
  	 
  	 # $a1 points to the privious node 
  	 # $a3 to the current node that is to be deleted
  	 # $a2 has the address to the next node
  	 la $t9, headNode
  	 bne $a1,$t9,normalNode
  	 sw $a2 , 0($a1)
  	 j node_deleted
  	 
    normalNode:	 
  	 sw $a2 , 24($a1)
  	 j node_deleted
  	 
    not_found_to_delete:
        display("\nPatient ID or test name not found.\n")
        j whileloop
   
    node_deleted:
        display("\nDeleted.\n")
        j whileloop
        
#-----------------------------------------------------------------------------------------------------------------
print_data:                    #the data is in $t0
   li $v0, 1                   #syscall to print integer
   move $a0,$t0                #print patient ID
   syscall
 
   li $v0, 11                  # Print character syscall is 11
   li $a0, ':'                 #print :b
   syscall
 
   li $v0, 11                  # Print character syscall is 11
   li $a0, ' '                 # print the space
   syscall
 
   li $v0, 4                   #print test name
   la $a0,4($a3)
   syscall
 
   li $v0, 11
   la $a0,','
   syscall
 
   li $v0, 11                  # Print character syscall is 11
   li $a0, ' '                 # print the space
   syscall
 
   li $v0, 1                  # Print character syscall is 11
   lw $a0, 8($a3)             # print the year
   syscall
 
   li $v0, 11                  # Print character syscall is 11
   li $a0, '-'                 # print -
   syscall
 
   li $v0, 1                  # Print character syscall is 11
   lw $a0, 12($a3)             # print the month
   syscall
 
   li $v0, 11
   la $a0,','
   syscall
 
   li $v0, 11                  # Print character syscall is 11
   li $a0, ' '                 # print the space
   syscall
 
   l.s $f12,16($a3)
   li $v0, 2                   #syscall to print float   all_tests
   syscall
 
   lb $t6,4($a3)               # if it's BPT then there is result2
   bne $t6 ,'B' , nl
   lb $t6,5($a3)
   bne $t6 ,'P' , nl
   lb $t6,6($a3)
   bne $t6 ,'T' , nl
 
   li $v0, 11
   la $a0,','
   syscall
 
   li $v0, 11                  # Print character syscall is 11
   li $a0, ' '                 # print the space
   syscall
 
   l.s $f12,20($a3)
   li $v0, 2                   #syscall to print float   all_tests
   syscall

 nl:
   li $v0, 11                  # Print character syscall is 11
   li $a0, 10                  # ASCII code for newline character
   syscall
   jr $t8

#-----------------------------------------------------------------------------------------------------------------
print_all:
    la $a1,headNode
    lw $a2,0($a1)
    print_linked_list:
    	 beq $zero, $a2, finish_printing                #if the next address is not null move to it            
   	 lw $t0,0($a2)                          # t0 contains the ID of the patients in the linked list
  	 move $a3,$a2
  	 lw $a2,24($a2)                            #$a2 has the next address (pointing to the next ID)
  	 la $t7,print_data                        #to use jump and link reg
 	 jalr $t8,$t7                             #current link is stored in $t8
  	 j  print_linked_list
finish_printing:
    jr $ra
#-----------------------------------------------------------------------------------------------------------------
terminate:
    display("\nOperation ended...\nback to menu\n")
    j whileloop
    