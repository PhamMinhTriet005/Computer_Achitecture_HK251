.data
input_file:   .asciiz  "input.txt"           # use the full address if you cannot open the file "C:\\Users\\ADMIN\\Downloads\\KTMT_HK251_Assignment\\codebase\\input.txt"
desired_file: .asciiz "desired.txt"         # use the full address if you cannot open the file "C:\\Users\\ADMIN\\Downloads\\KTMT_HK251_Assignment\\codebase\\desired.txt"
output_file:  .asciiz "output.txt"          # use the full address if you cannot open the file "C:\\Users\\ADMIN\\Downloads\\KTMT_HK251_Assignment\\codebase\\output.txt"
buf_size:     .word 32768
buffer:       .space 32768
NUM_SAMPLES:  .word 10
desired:      .space 40
input:        .space 40
crosscorr:    .space 40
autocorr:     .space 40
R:            .space 400
coeff:        .space 40
ouput:        .space 40
mmse:         .float 0.0
zero_f:       .float 0.0
one_f:        .float 1.0
ten:          .float 10.0
hundred:      .float 100.0
half:         .float 0.5
minus_half:   .float -0.5
zero:         .float 0.0
null:         .byte 0
header_filtered: .asciiz "Filtered output: "
header_mmse:  .asciiz "\nMMSE: "
space_str:    .asciiz " "
newline_str:  .asciiz "\n"
str_buf:      .space 32
temp_str:     .space 32
error_open:   .asciiz "Error: Can not open file"
error_size_msg:   .asciiz "Error: size not match"
desired_header:   .asciiz "=== Desired Array ===\n"
input_header:     .asciiz "=== Input Array ===\n"
coeff_header:     .asciiz "=== Coefficient Array ===\n"
crosscorr_header: .asciiz "=== Crosscorrelation Array ===\n"
autocorr_header:  .asciiz "=== Autocorrelation Array ===\n"
matrix_header:    .asciiz "=== Matrix R ===\n"

.text
.globl main

main:
    # --- Open and read input file for input[] ---
    # Open input.txt
    li   $v0, 13            # Open file syscall
    la   $a0, input_file
    li   $a1, 0             # Read mode
    li   $a2, 0
    syscall
    move $s0, $v0           # Save file descriptor in $s0

    # Read input file
    li   $v0, 14            # Read file syscall
    move $a0, $s0           # File descriptor
    la   $a1, buffer
    lw   $a2, buf_size
    syscall
    move $s4, $v0           # Save input file size in $s4

    # Close input file
    li   $v0, 16            # Close file syscall
    move $a0, $s0
    syscall

    # Parse buffer and store floats in input[]
    la   $a0, buffer        # Input buffer
    la   $a1, input         # Output array
    li   $a2, 10            # Number of floats
    jal  parseFloats
    move $t8, $v0

    


    # --- Open and read desired file ---
    # Open desired.txt
    li   $v0, 13            # Open file syscall
    la   $a0, desired_file
    li   $a1, 0             # Read mode
    li   $a2, 0
    syscall
    move $s0, $v0           # Save file descriptor in $s0

    # Read desired file
    li   $v0, 14            # Read file syscall
    move $a0, $s0           # File descriptor
    la   $a1, buffer
    lw   $a2, buf_size
    syscall
    move $s5, $v0           # Save desired file size in $s5

    # Close desired file
    li   $v0, 16            # Close file syscall
    move $a0, $s0
    syscall

    

    # Parse buffer and store floats in desired[]
    la   $a0, buffer        # Input buffer
    la   $a1, desired       # Output array
    li   $a2, 10            # Number of floats
    jal  parseFloats
    move $t9, $v0

    

    # Check if sizes match
    bne  $t8, $t9, error_size

    

    # --- compute crosscorrelation ---
    la   $a0, desired
    la   $a1, input
    la   $a2, crosscorr
    lw   $a3, NUM_SAMPLES
    jal  computeCrosscorrelation

     # --- compute autocorrelation ---
    ## TODO computeAutocorrelation
    la $a0, input
    la $a1, autocorr
    lw $a2, NUM_SAMPLES
    jal computeAutocorrelation

    # --- create Toeplitz matrix ---
    ## TODO createToeplitzMatrix
    la $a0, autocorr
    la $a1, R
    lw $a2, NUM_SAMPLES
    jal createToeplitzMatrix

    

    # --- solveLinearSystem ---
    # TODO
    la $a0, R
    la $a1, crosscorr
    la $a2, coeff
    lw $a3, NUM_SAMPLES
    jal solveLinearSystem


    # --- applyWienerFilter ---
    # TODO
    la $a0, input
    la $a1, coeff
    la $a2, ouput
    lw $a3, NUM_SAMPLES
    jal applyWienerFilter

    # --- compute MMSE ---
    la $a0, desired
    la $a1, ouput
    lw $a2, NUM_SAMPLES
    jal computeMMSE
    
    # Store result in mmse variable
    la $t0, mmse
    s.s $f0, 0($t0)

    # --- Open output file ---
    ## TODO
    li $v0, 13
    la $a0, output_file
    li $a1, 1
    li $a2, 0
    syscall
    move $s0, $v0

    # --- Write "Filtered output: " ---
    ## TODO
    li $v0, 15
    move $a0, $s0
    la $a1, header_filtered
    li $a2, 17
    syscall

    # --- Write filtered outputs with 1 decimal place ---
    lw $s1, NUM_SAMPLES
    subi $s5, $s1, 1        # $s5 = NUM_SAMPLES - 1 (last index)
    la $s7, ouput
    move $s2, $zero

loop_write_outputs:
    bge $s2, $s1, end_write_outputs
    
    sll $t0, $s2, 2
    add $t0, $t0, $s7
    l.s $f12, 0($t0)
    
    jal round_to_1dec
    
    # Clear buffer before writing
    la $t1, str_buf
    li $t3, 32
clear_buf_loop:
    beq $t3, $zero, clear_buf_done
    sb $zero, 0($t1)
    addi $t1, $t1, 1
    addi $t3, $t3, -1
    j clear_buf_loop
    
clear_buf_done:
    la $a0, str_buf
    mov.s $f12, $f0
    li $a1, 1
    jal float_to_str
    
    # Save length before writing to file
    move $t4, $v0
    
    # Write converted number to file
    li $v0, 15
    move $a0, $s0
    la $a1, str_buf
    move $a2, $t4
    syscall

    beq $s2, $s5, skip_space_output
    
    # Write space after number
    li $v0, 15
    move $a0, $s0
    la $a1, space_str
    li $a2, 1
    syscall

skip_space_output:
    addi $s2, $s2, 1
    j loop_write_outputs

end_write_outputs:
    # --- Write "\nMMSE: " ---
    ## TODO
    ## TODO
    li $v0, 15
    move $a0, $s0
    la $a1, header_mmse
    li $a2, 7
    syscall

    # --- Write MMSE with 1 decimal ---
    la $t0, mmse
    l.s $f12, 0($t0)
    
    jal round_to_1dec
    
    # Clear buffer before writing
    la $t1, str_buf
    li $t3, 32
clear_buf_mmse:
    beq $t3, $zero, clear_buf_mmse_done
    sb $zero, 0($t1)
    addi $t1, $t1, 1
    addi $t3, $t3, -1
    j clear_buf_mmse
    
clear_buf_mmse_done:
    # Convert to string with 1 decimal
    la $a0, str_buf
    mov.s $f12, $f0
    li $a1, 1
    jal float_to_str
    
    # Save length before writing to file
    move $t4, $v0
    
    # Write to file
    li $v0, 15
    move $a0, $s0
    la $a1, str_buf
    move $a2, $t4
    syscall
    
    # --- Close output file ---
    li $v0, 16
    move $a0, $s0
    syscall


        # --- Print to console: Filtered output and MMSE ---
    
    # Print "Filtered output: "
    li   $v0, 4
    la   $a0, header_filtered
    syscall
    
    # Print filtered outputs with 1 decimal place
    lw   $s1, NUM_SAMPLES
    subi $s5, $s1, 1        # $s5 = NUM_SAMPLES - 1 (last index)
    la   $s7, ouput
    move $s2, $zero

console_write_outputs:
    bge  $s2, $s1, console_end_write_outputs
    
    sll  $t0, $s2, 2
    add  $t0, $t0, $s7
    l.s  $f12, 0($t0)
    
    jal  round_to_1dec
    
    # Clear buffer before writing
    la   $t1, str_buf
    li   $t3, 32
console_clear_buf_loop:
    beq  $t3, $zero, console_clear_buf_done
    sb   $zero, 0($t1)
    addi $t1, $t1, 1
    addi $t3, $t3, -1
    j    console_clear_buf_loop
    
console_clear_buf_done:
    la   $a0, str_buf
    mov.s $f12, $f0
    li   $a1, 1
    jal  float_to_str
    
    # Print to console
    li   $v0, 4
    la   $a0, str_buf
    syscall
    
    beq  $s2, $s5, console_skip_space_output
    
    # Print space after number
    li   $v0, 4
    la   $a0, space_str
    syscall

console_skip_space_output:
    addi $s2, $s2, 1
    j    console_write_outputs

console_end_write_outputs:
    
    # Print MMSE
    li   $v0, 4
    la   $a0, header_mmse
    syscall
    
    la   $t0, mmse
    l.s  $f12, 0($t0)
    
    jal  round_to_1dec
    
    # Clear buffer before writing
    la   $t1, str_buf
    li   $t3, 32
console_clear_buf_mmse:
    beq  $t3, $zero, console_clear_buf_mmse_done
    sb   $zero, 0($t1)
    addi $t1, $t1, 1
    addi $t3, $t3, -1
    j    console_clear_buf_mmse
    
console_clear_buf_mmse_done:
    la   $a0, str_buf
    mov.s $f12, $f0
    li   $a1, 1
    jal  float_to_str
    
    # Print to console
    li   $v0, 4
    la   $a0, str_buf
    syscall
   

    
    # --- Exit program ---
    li $v0, 10
    syscall


# ---------------------------------------------------------
# parseFloats($a0=buffer, $a1=output_array, $a2=count)
# Parses float values from buffer separated by spaces
# ---------------------------------------------------------
parseFloats:
    addi $sp, $sp, -16
    # B?????c 1: Copy t??? $a v??o $s TR?????C
    move $s0, $a0           # $s0 = buffer pointer
    move $s1, $a1           # $s1 = output array pointer
    move $s2, $a2           # $s2 = count
    li   $s3, 0             # $s3 = index counter
    
    # B?????c 2: C???p ph??t stack v?? l??u registers (gi?? tr??? m???i)
    addi $sp, $sp, -16
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)
    sw   $s2, 12($sp)

parseFloats_loop:
    bge  $s3, $s2, parseFloats_done

    # Convert string to float
    move $a0, $s0
    jal  stringToFloat
    swc1 $f0, 0($s1)        # Store float in array

    # Skip to next number
    jal  skipToNextNumber
    lb   $t0, 0($s0)       # kiểm tra ký tự hiện tại
    beq  $t0, 0, parseFloats_done  # nếu hết buffer thì thoát


    # Move to next position in array
    addi $s1, $s1, 4        # Move 4 bytes (size of float)
    addi $s3, $s3, 1
    j    parseFloats_loop

parseFloats_done:
    lw   $ra, 0($sp)
    lw   $s0, 4($sp)
    lw   $s1, 8($sp)
    lw   $s2, 12($sp)
    addi $sp, $sp, 16

    move $v0, $s3       # trả v�? số lượng float đã đ�?c
    jr   $ra

# ---------------------------------------------------------
# stringToFloat($a0=string) -> $f0
# Converts a string to float
# ---------------------------------------------------------
stringToFloat:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    la $t0, zero_f
    l.s  $f0, 0($t0)           # Result = 0.0
    l.s  $f1, 0($t0)          # Integer part = 0.0
    l.s  $f2, 0($t0)          # Decimal part = 0.0

    la $t0, one_f
    l.s  $f3, 0($t0)         # Multiplier for decimal = 1.0

    la $t0, ten
    l.s  $f4, 0($t0)           # 10.0

    li   $t0, 0             # Sign flag (0 = positive)
    li   $t1, 0             # After decimal flag
    move $t2, $a0           # Current char pointer

str2f_loop:
    lb   $t3, 0($t2)        # Load character
    la   $t4, null
    lb   $t4, 0($t4)
    beq  $t3, $t4, str2f_done # End of string
    beq  $t3, 32, str2f_done # Space

    # Check for minus sign
    beq  $t3, 45, str2f_minus
    
    # Check for decimal point
    beq  $t3, 46, str2f_decimal

    # Convert digit
    subi  $t3, $t3, 48       # '0' = 48
    mtc1  $t3, $f5
    cvt.s.w $f5, $f5

    beq  $t1, 0, str2f_int

str2f_dec:
    mul.s $f5, $f5, $f3
    add.s $f2, $f2, $f5
    mul.s $f3, $f3, $f4
    j    str2f_done

str2f_int:
    mul.s $f1, $f1, $f4
    add.s $f1, $f1, $f5

str2f_next:
    addi $t2, $t2, 1
    j    str2f_loop

str2f_minus:
    li   $t0, 1             # Set negative flag
    addi $t2, $t2, 1
    j    str2f_loop

str2f_decimal:
    li   $t1, 1             # Set decimal flag
    div.s $f3, $f3, $f4     # $f3 = 1.0 / 10.0 = 0.1
    addi $t2, $t2, 1
    j    str2f_loop

str2f_done:
    add.s $f0, $f1, $f2
    beq  $t0, 0, str2f_positive
    neg.s $f0, $f0

str2f_positive:
    move $s0, $t2           # Update buffer pointer
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# ---------------------------------------------------------
# skipToNextNumber($a0=current_string_ptr) -> updates $s0
# Assumes exactly 1 space between numbers
# ---------------------------------------------------------
skipToNextNumber:
    move $t2, $s0
skip_loop:
    lb   $t3, 0($t2)
    beq  $t3, 0, skip_done      # End of buffer
    beq  $t3, 32, skip_space    # Space found
    addi $t2, $t2, 1
    j    skip_loop

skip_space:
    addi $t2, $t2, 1            # Skip the 1 space

skip_done:
    move $s0, $t2               # Update global buffer pointer
    jr   $ra



# ---------------------------------------------------------
# computeAutocorrelation(input[], autocorr[], N)
# ---------------------------------------------------------
computeAutocorrelation:
    ## TODO
    li $t0, 500 #M = 500
    bgt $a2, $t0, if_computeAutocorrelation #if (N < M) M = N
    move $t0, $a2
if_computeAutocorrelation:
    move $t1, $zero #int k = 0
for_loop_computeAutocorrelation:
    bge $t1, $t0, end_for_loop_computeAutocorrelation
    
    la $t7, zero_f
    l.s $f0, 0($t7) #float sum = 0
    move $t2, $t1 #int n = k    
    inner_loop_computeAutocorrelation:
    	bge $t2, $a2, end_inner_loop_computeAutocorrelation
    	
    	mul $t3, $t2, 4
    	add $t4, $a0, $t3
    	l.s $f1, 0($t4) #f1 = signal[n]
    	
    	sub $t3, $t2, $t1 #t3 = n - k
    	mul $t3, $t3, 4
    	add $t4, $a0, $t3
    	l.s $f2, 0($t4) #f2 = signal[n-k]
    	
    	mul.s $f3, $f1, $f2 #f3 = desired[n] * input[n-k]
    	add.s $f0, $f0, $f3
    	
    	addi $t2, $t2, 1
    	j inner_loop_computeAutocorrelation
    end_inner_loop_computeAutocorrelation:
    
    mtc1 $a2, $f1
    cvt.s.w $f1, $f1 #f1 = N
    div.s $f0, $f0, $f1
    
    mul $t2, $t1, 4
    add $t3, $a1, $t2
    
    s.s $f0, 0($t3)
    
    addi $t1, $t1, 1
    j for_loop_computeAutocorrelation
    
end_for_loop_computeAutocorrelation:
    jr $ra


# ---------------------------------------------------------
# computeCrosscorrelation(desired[], input[], crosscorr[], N)
# ---------------------------------------------------------
computeCrosscorrelation:
    ## TODO
    li $t0, 500 #M = 500
    bgt $a3, $t0, if_computeCrosscorrelation #if (N < M) M = N
    move $t0, $a3
if_computeCrosscorrelation:
    move $t1, $zero #int k = 0
for_loop_computeCrosscorrelation:
    bge $t1, $t0, end_for_loop_computeCrosscorrelation

    la $t7, zero_f
    l.s $f0, 0($t7) #float sum = 0
    move $t2, $t1 #int n = k    
    inner_loop_computeCrosscorrelation:
    	bge $t2, $a3, end_inner_loop_computeCrosscorrelation
    	
    	mul $t3, $t2, 4
    	add $t4, $a0, $t3
    	l.s $f1, 0($t4) #f1 = desired[n]
    	
    	sub $t3, $t2, $t1 #t3 = n - k
    	mul $t3, $t3, 4
    	add $t4, $a1, $t3
    	l.s $f2, 0($t4) #f2 = input[n-k]
    	
    	mul.s $f3, $f1, $f2 #f3 = desired[n] * input[n-k]
    	add.s $f0, $f0, $f3
    	
    	addi $t2, $t2, 1
    	j inner_loop_computeCrosscorrelation
    end_inner_loop_computeCrosscorrelation:
    
    mtc1 $a3, $f1
    cvt.s.w $f1, $f1 #f1 = N
    div.s $f0, $f0, $f1
    
    mul $t2, $t1, 4
    add $t3, $a2, $t2
    
    s.s $f0, 0($t3)
    
    addi $t1, $t1, 1
    j for_loop_computeCrosscorrelation
    
end_for_loop_computeCrosscorrelation:
    jr $ra

# ---------------------------------------------------------
# createToeplitzMatrix(autocorr[], R[][], N)
# ---------------------------------------------------------
createToeplitzMatrix:
    ## TODO
    li $t0, 500 #M = 500
    bgt $a2, $t0, if_createToeplitzMatrix #if (N < M) M = N
    move $t0, $a2
if_createToeplitzMatrix:
    move $t1, $zero #int i = 0
for_loop_createToeplitzMatrix:
    bge $t1, $t0, exit_for_loop_createToeplitzMatrix
    move $t2, $zero #int j = 0
    inner_loop_createToeplitzMatrix:
    	bge $t2, $t0, exit_inner_loop_createToeplitzMatrix
    	
    	sub $t3, $t1, $t2 #t3 = abs(i - j)
    	bge $t3, $zero, next_createToeplitzMatrix
    	negu $t3, $t3
    next_createToeplitzMatrix:
        mul $t3, $t3, 4
    	add $t3, $t3, $a0
    	l.s $f0, 0($t3)  #f0 = autocorr[abs(i - j)]
    	
    	mul  $t4, $t1, $t0     # $t4 = i * M
    	add  $t4, $t4, $t2     # $t4 = i * M + j
    	mul  $t4, $t4, 4       # $t4 = offset byte
    	add  $t6, $a1, $t4     # $t6 = ?????a ch??? R[i][j]

    	
    	s.s $f0, 0($t6)
    	
    	addi $t2, $t2, 1
    	j inner_loop_createToeplitzMatrix
    exit_inner_loop_createToeplitzMatrix:
    addi $t1, $t1, 1    
    j for_loop_createToeplitzMatrix
exit_for_loop_createToeplitzMatrix: 
    jr $ra

# ---------------------------------------------------------
# solveLinearSystem(A[][], b[], x[], N)
# ---------------------------------------------------------
solveLinearSystem:
    # TODO
    li $t0, 500 #M = 500
    bgt $a3, $t0, if_solveLinearSystem #if (N < M) M = N
    move $t0, $a3
if_solveLinearSystem:
    addi $t1, $t0, 1
    mul $t1, $t1, $t0
    mul $t1, $t1, 4
    sub $sp, $sp, $t1 #float Aug[M][M+1]

    move $t2, $zero #int i = 0
for_loop_solveLinearSystem_1:
    bge $t2, $t0, exit_for_loop_solveLinearSystem_1

    move $t3, $zero #int j = 0
    inner_loop_solveLinearSystem_1:
        bge $t3, $t0, exit_inner_loop_solveLinearSystem_1

        mul $t4, $t2, $t0
        add $t4, $t4, $t3
        sll $t4, $t4, 2
        add $t4, $t4, $a0

        l.s $f0, 0($t4) #f0 = A[i][j]

        addi $t5, $t0, 1
        mul $t5, $t5, $t2
        add $t5, $t5, $t3
        sll $t5, $t5, 2
        add $t5, $t5, $sp   #t5 = base address of Aug[i][j]

        s.s $f0, 0($t5)

        addi $t3, $t3, 1
        j inner_loop_solveLinearSystem_1
    exit_inner_loop_solveLinearSystem_1:

    addi $t2, $t2, 1
    j for_loop_solveLinearSystem_1
exit_for_loop_solveLinearSystem_1:

    move $t2, $zero #int i = 0
for_loop_solveLinearSystem_2:
    bge $t2, $t0, exit_for_loop_solveLinearSystem_2

    sll $t3, $t2, 2
    add $t3, $t3, $a1
    l.s $f0, 0($t3)

    addi $t4, $t0, 1
    mul $t4, $t4, $t2
    add $t4, $t4, $t0
    sll $t4, $t4, 2
    add $t4, $t4, $sp

    s.s $f0, 0($t4)

    addi $t2, $t2, 1
    j for_loop_solveLinearSystem_2
exit_for_loop_solveLinearSystem_2:

    move $t4, $zero #int k = 0
for_loop_solveLinearSystem_3:
    bge $t4, $t0, exit_for_loop_solveLinearSystem_3

    move $t5, $t4 #int p = k
    addi $t6, $t0, 1
    mul $t6, $t4, $t6
    add $t6, $t6, $t4
    sll $t6, $t6, 2
    add $t6, $t6, $sp
    l.s $f0, 0($t6) #f0 = Aug[k][k] = maxValue
    abs.s $f0, $f0 #f0 =  fabs(Aug[k][k]) = maxValue

    addi $t7, $t4, 1 #int i = k + 1
    inner_loop_solveLinearSystem_3_1:
        bge $t7, $t0, exit_inner_loop_solveLinearSystem_3_1

        addi $t8, $t0, 1
        mul $t8, $t7, $t8
        add $t8, $t8, $t4
        sll $t8, $t8, 2
        add $t8, $t8, $sp
        l.s $f1, 0($t8)
        abs.s $f1, $f1
        c.le.s $f1, $f0 #if (fabs(Aug[i][k] > maxValue) { ... })
        bc1f IF_inner_loop_solveLinearSystem_3_1
        move $t5, $t7
        mov.s $f0, $f1
    IF_inner_loop_solveLinearSystem_3_1:

        addi $t7, $t7, 1
        j inner_loop_solveLinearSystem_3_1
    exit_inner_loop_solveLinearSystem_3_1:

    beq $t5, $t4, IF_for_loop_solveLinearSystem_3

        move $t7, $zero #int j = 0
        inner_loop_solveLinearSystem_3_2:
            bgt $t7, $t0, exit_inner_loop_solveLinearSystem_3_2

            add $t8, $t0, 1
            mul $t8, $t5, $t8
            add $t8, $t8, $t7
            sll $t8, $t8, 2
            add $t8, $t8, $sp
            l.s $f12, 0($t8) #temp = Aug[p][j]

            add $t9, $t0, 1
            mul $t9, $t4, $t9
            add $t9, $t7, $t9

            sll $t9, $t9, 2
            add $t9, $t9, $sp
            l.s $f11, 0($t9)

            s.s $f11, 0($t8)
            s.s $f12, 0($t9)

            addi $t7, $t7, 1
            j inner_loop_solveLinearSystem_3_2
        exit_inner_loop_solveLinearSystem_3_2:
    IF_for_loop_solveLinearSystem_3:


    addi $t7, $t4, 1 #int i = k + 1
    inner_loop_solveLinearSystem_3_3:
        bge $t7, $t0, exit_inner_loop_solveLinearSystem_3_3

        addi $t8, $t0, 1
        mul $t8, $t7, $t8
        add $t8, $t8, $t4
        sll $t8, $t8, 2
        add $t8, $t8, $sp
        l.s $f11, 0($t8) # f11 = aug[i][k]

        addi $t9, $t0, 1
        mul $t9, $t4, $t9
        add $t9, $t9, $t4
        sll $t9, $t9, 2
        add $t9, $t9, $sp
        l.s $f12, 0($t9) # f12 = aug[k][k]

        div.s $f10, $f11, $f12 # factor = aug[i][k] / aug[k][k]
        la $t9, zero_f
        l.s $f12, 0($t9)
        s.s $f12, 0($t8)

        addi $t8, $t4, 1 #int j = k + 1
        se_inner_loop_loop_solveLinearSystem_3_3:
            bgt $t8, $t0, exit_se_inner_loop_loop_solveLinearSystem_3_3

            addi $t9, $t0, 1
            mul $t9, $t9, $t4
            add $t9, $t9, $t8
            sll $t9, $t9, 2
            add $t9, $t9, $sp
            l.s $f12, 0($t9) # f12 = Aug[k][j]
            mul.s $f12, $f12, $f10 # factor * Aug[k][j]

            addi $t9, $t0, 1
            mul $t9, $t9, $t7
            add $t9, $t9, $t8
            sll $t9, $t9, 2
            add $t9, $t9, $sp
            l.s $f11, 0($t9) # f11 = Aug[i][j]
            sub.s $f11, $f11, $f12
            s.s $f11, 0($t9) # Aug[i][j] = Aug[i][j] - factor * Aug[k][j];


            addi $t8, $t8, 1
            j se_inner_loop_loop_solveLinearSystem_3_3
	exit_se_inner_loop_loop_solveLinearSystem_3_3:

        addi $t7, $t7, 1
        j inner_loop_solveLinearSystem_3_3
    exit_inner_loop_solveLinearSystem_3_3:


    addi $t4, $t4, 1
    j for_loop_solveLinearSystem_3
exit_for_loop_solveLinearSystem_3:

    subi $t4, $t0, 1 #int i = M - 1
    move $t5, $zero
for_loop_solveLinearSystem_4:
    blt $t4, $t5, exit_for_loop_solveLinearSystem_4

    addi $t6, $t0, 1
    mul $t6, $t6, $t4
    add $t6, $t6, $t0
    sll $t6, $t6, 2
    add $t6, $t6, $sp
    l.s $f0, 0($t6) # f0 = s = Aug[i][M]

    addi $t7, $t4, 1 #int j = i + 1
    inner_loop_solveLinearSystem_4:
        bge $t7, $t0, exit_inner_loop_solveLinearSystem_4

        addi $t8, $t0, 1
        mul $t8, $t8, $t4
        add $t8, $t8, $t7
        sll $t8, $t8, 2
        add $t8, $t8, $sp
        l.s $f11, 0($t8) # f11 = Aug[i][j]
        

        move $t8, $t7
        sll $t8, $t8, 2
        move $t9, $a2
        add $t8, $t8, $t9
        l.s $f12, 0($t8) #$f12 = x[j]

        mul.s $f10, $f11, $f12 # f10 = Aug[i][j] * x[j]
        sub.s $f0, $f0, $f10

        addi $t7, $t7, 1
        j inner_loop_solveLinearSystem_4
    exit_inner_loop_solveLinearSystem_4:

    sll $t7, $t4, 2
    move $t8, $a2
    add $t7, $t7, $t8

    addi $t8, $t0, 1
    mul $t8, $t8, $t4
    add $t8, $t8, $t4
    sll $t8, $t8, 2
    add $t8, $t8, $sp
    l.s $f11, 0($t8) # f11 = Aug[i][i]

    div.s $f0, $f0, $f11
    s.s $f0, 0($t7)

    subi $t4, $t4, 1
    j for_loop_solveLinearSystem_4
exit_for_loop_solveLinearSystem_4:
    add $sp, $sp, $t1
    jr $ra

# ---------------------------------------------------------
# applyWienerFilter(input[], coefficients[], output[], N)
# ---------------------------------------------------------
applyWienerFilter:
    # TODO
    li $t0, 500 #M = 500
    bgt $a3, $t0, if_applyWienerFilter #if (N < M) M = N
    move $t0, $a3
if_applyWienerFilter:
    li $t1, 0 #int n = 0
for_loop_applyWienerFilter:
    bge $t1, $a3, exit_for_loop_applyWienerFilter
    mul $t2, $t1, 4
    add $t2, $t2, $a2 #t2 = base address of ouput[n]
    la $t3, zero_f
    l.s $f0, 0($t3)
    s.s $f0, 0($t2)

    li $t3, 0 #int k = 0
    inner_loop_applyWienerFilter:
        bge $t3, $t0, exit_inner_loop_applyWienerFilter

        blt $t1, $t3, IF_applyWienerFilter #if (n >= k) {...}

        mul $t4, $t3, 4
        add $t4, $a1, $t4
        l.s $f1, 0($t4) # f1 = coefficients[k]

        sub $t5, $t1, $t3
        mul $t5, $t5, 4
        add $t5, $t5, $a0
        l.s $f2, 0($t5) #f2 = input[n - k]

        mul.s $f12, $f1, $f2 # f12 = coefficients[k] * input[n-k]

        l.s $f3, 0($t2) #f3 = output[n]
        add.s $f3, $f3, $f12 # ouput[n] += coefficients[k] * input[n-k]
        s.s $f3, 0($t2) #store back to base address

        IF_applyWienerFilter:
        addi $t3, $t3, 1
        j inner_loop_applyWienerFilter
    exit_inner_loop_applyWienerFilter:
    addi $t1, $t1, 1
    j for_loop_applyWienerFilter
exit_for_loop_applyWienerFilter:
    jr $ra

# ---------------------------------------------------------
# computeMMSE(desired[], output[], N) -> $f0
# Parameters:
#   $a0 = address of desired[] array
#   $a1 = address of output[] array
#   $a2 = N (number of samples)
# Returns:
#   $f0 = MMSE (Mean Squared Error) as float
# ---------------------------------------------------------
computeMMSE:
    # float mse = 0
    la $t0, zero_f
    l.s $f0, 0($t0)         # $f0 = mse = 0.0
    
    # Convert N to float for later division
    mtc1 $a2, $f5
    cvt.s.w $f5, $f5         # $f5 = N as float
    
    # int n = 0
    li $t1, 0
    
# for loop: n < N
for_loop_computeMMSE:
    bge $t1, $a2, exit_for_loop_computeMMSE
    
    # double error = desired[n] - output[n]
    # Load desired[n]
    sll $t2, $t1, 2         # offset = n * 4
    add $t2, $t2, $a0       # address = desired + offset
    l.s $f1, 0($t2)         # $f1 = desired[n]
    
    # Load output[n]
    sll $t2, $t1, 2         # offset = n * 4
    add $t2, $t2, $a1       # address = output + offset
    l.s $f2, 0($t2)         # $f2 = output[n]
    
    # error = desired[n] - output[n]
    sub.s $f3, $f1, $f2     # $f3 = error
    
    # mse += error * error
    mul.s $f4, $f3, $f3     # $f4 = error * error
    add.s $f0, $f0, $f4     # $f0 = mse + (error * error)
    
    # n++
    addi $t1, $t1, 1
    j for_loop_computeMMSE
    
exit_for_loop_computeMMSE:
    # return mse / N
    div.s $f0, $f0, $f5     # $f0 = mse / N
    
    jr $ra

# ---------------------------------------------------------
# round_to_1dec($f12) -> $f0
# Rounds a float to 1 decimal place
# ---------------------------------------------------------
round_to_1dec:
    # f3 = f12 * 10
    # if f3 < 0:
    #     f3 = f3 - 0.5
    # else:
    #     f3 = f3 + 0.5
    # f4 = int(f3)
    # f0 = float(f4) / 10
    ## TODO
    la $t0, ten
    l.s $f1, 0($t0)
    mul.s $f2, $f12, $f1
    
    la $t0, zero_f
    l.s $f3, 0($t0)
    
    la $t1, half
    l.s $f4, 0($t1)
    
    c.lt.s $f2, $f3
    bc1f round_positive
    
    # Negative case: subtract 0.5
    sub.s $f2, $f2, $f4
    j round_convert
    
round_positive:
    # Positive case: add 0.5
    add.s $f2, $f2, $f4
    
round_convert:
    # Convert to integer
    cvt.w.s $f5, $f2
    mfc1 $t2, $f5
    
    # Convert back to float
    mtc1 $t2, $f5
    cvt.s.w $f5, $f5
    
    # Divide by 10
    div.s $f0, $f5, $f1
    
    # Check if result is 0, if so convert -0.0 to 0.0
    la $t0, zero_f
    l.s $f1, 0($t0)
    c.eq.s $f0, $f1
    bc1f skip_zero_fix
    
    # Result is 0, make sure it's positive 0.0
    abs.s $f0, $f0
    
skip_zero_fix:
    jr $ra

# ---------------------------------------------------------
# float_to_str($a0=buffer, $f12=value, $a1=decimals) -> $v0=length
# 
# Converts a float to ASCII string with specified decimal places.
# Uses pre-allocated stack space to avoid overwriting caller data.
# ---------------------------------------------------------
float_to_str:
    # Pre-allocate stack space (20 bytes for registers + 80 bytes for digit buffer)
    addi $sp, $sp, -100
    sw $ra, 96($sp)
    sw $s0, 92($sp)
    sw $s1, 88($sp)
    sw $s2, 84($sp)
    sw $s3, 80($sp)
    
    move $s0, $a0
    move $s1, $a1
    move $s2, $zero
    move $s3, $sp
    li $s4, 0              # $s4 = flag for negative (0 = positive, 1 = negative)
    
    # --- Handle negative sign ---
    la $t0, zero_f
    l.s $f0, 0($t0)
    c.lt.s $f12, $f0
    bc1f skip_neg_sign
    
    li $t1, '-'
    sb $t1, 0($s0)
    addi $s0, $s0, 1
    addi $s2, $s2, 1
    li $s4, 1              # Set negative flag
    neg.s $f12, $f12      # Convert to positive for processing
    
skip_neg_sign:
    # --- Calculate multiplier: 10^decimals ---
    la $t0, one_f
    l.s $f1, 0($t0)
    move $t1, $s1
    
calc_mult_loop:
    beq $t1, $zero, calc_mult_done
    la $t0, ten
    l.s $f2, 0($t0)
    mul.s $f1, $f1, $f2
    addi $t1, $t1, -1
    j calc_mult_loop
    
calc_mult_done:
    mul.s $f12, $f12, $f1
    
    # --- Convert to integer (NO rounding here - already rounded in main) ---
    cvt.w.s $f3, $f12
    mfc1 $t2, $f3
    
    # --- Calculate 10^decimals for division ---
    li $t3, 1
    move $t4, $s1
    
calc_pow10_loop:
    beq $t4, $zero, calc_pow10_done
    li $t9, 10
    mul $t3, $t3, $t9
    addi $t4, $t4, -1
    j calc_pow10_loop
    
calc_pow10_done:
    # Now: $t2 = scaled int, $t3 = 10^decimals
    
    # --- Extract integer and fractional parts ---
    div $t2, $t3
    mflo $t4
    mfhi $t5
    
    # --- Convert integer part to digits ---
    beq $t4, $zero, int_part_zero
    
    # Push digits to stack buffer (right to left)
    move $t6, $t4
    move $t7, $s3          # use digit buffer
    
push_digits:
    beq $t6, $zero, done_pushing
    li $t9, 10
    div $t6, $t9
    mfhi $t8
    addi $t8, $t8, '0'
    sb $t8, 0($t7)
    addi $t7, $t7, 1
    mflo $t6
    j push_digits
    
done_pushing:
    # Pop digits from stack in reverse (left to right)
    addi $t7, $t7, -1      # point to last digit pushed
    
pop_and_write:
    blt $t7, $s3, write_decimal_point
    lb $t8, 0($t7)
    sb $t8, 0($s0)
    addi $s0, $s0, 1
    addi $s2, $s2, 1
    addi $t7, $t7, -1
    j pop_and_write
    
int_part_zero:
    li $t8, '0'
    sb $t8, 0($s0)
    addi $s0, $s0, 1
    addi $s2, $s2, 1
    
write_decimal_point:
    # --- Add decimal point if needed ---
    beq $s1, $zero, finish_string
    
    li $t8, '.'
    sb $t8, 0($s0)
    addi $s0, $s0, 1
    addi $s2, $s2, 1
    
    # --- Write fractional digits ---
    move $t6, $t5
    move $t7, $s1
    move $t8, $t3
    
write_frac_digits:
    beq $t7, $zero, finish_string
    
    li $t9, 10
    div $t8, $t9
    mflo $t8
    div $t6, $t8
    mflo $t9
    addi $t9, $t9, '0'
    sb $t9, 0($s0)
    addi $s0, $s0, 1
    addi $s2, $s2, 1
    
    mfhi $t6
    addi $t7, $t7, -1
    j write_frac_digits
    
finish_string:
    # Don't write null terminator to buffer for file output
    # Just return the character count
    move $v0, $s2
    lw $s3, 80($sp)
    lw $s2, 84($sp)
    lw $s1, 88($sp)
    lw $s0, 92($sp)
    lw $ra, 96($sp)
    addi $sp, $sp, 100
    jr $ra

# ---------------------------------------------------------
# Error handler for size mismatch
# ---------------------------------------------------------
error_size:
    # Open output file for writing
    li   $v0, 13
    la   $a0, output_file
    li   $a1, 1             # Write mode
    li   $a2, 0
    syscall
    move $s0, $v0           # Save file descriptor
    
    # Write error message to output file
    li   $v0, 15            # Write file syscall
    move $a0, $s0
    la   $a1, error_size_msg
    li   $a2, 21            # Length of "Error: size not match"
    syscall
    
    # Close output file
    li   $v0, 16
    move $a0, $s0
    syscall
    
    # Exit program
    li   $v0, 10
    syscall

