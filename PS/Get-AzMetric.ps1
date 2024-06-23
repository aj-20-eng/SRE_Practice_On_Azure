
# Define the time range for the metrics
$startTime = (Get-Date).AddDays(-30) # Last 24 hours
$endTime = Get-Date

# Get all VMs in the subscription
$vms = Get-AzVM

# Initialize a collection to store the results
$results = @()

foreach ($vm in $vms) {
    $vmName = $vm.Name
    $resourceGroupName = $vm.ResourceGroupName

    # Get CPU utilization
    $cpuMetrics = Get-AzMetric -ResourceId $vm.Id -MetricName "Percentage CPU" -StartTime $startTime -EndTime $endTime
    $cpuAverage = ($cpuMetrics.Data | Measure-Object -Property Average -Average).Average

    # Get RAM utilization (Available Memory in bytes)
    $memoryMetrics = Get-AzMetric -ResourceId $vm.Id -MetricName "Available Memory Bytes" -StartTime $startTime -EndTime $endTime
    $memoryAverage = ($memoryMetrics.Data | Measure-Object -Property Average -Average).Average

    # Get VM size and total memory
    $vmSize = $vm.HardwareProfile.VmSize
    $vmSizeInfo = Get-AzVMSize -ResourceGroupName $resourceGroupName -VMName $vmName
    $totalMemory = ($vmSizeInfo | Where-Object { $_.Name -eq $vmSize }).MemoryInMB * 1MB # Convert MB to bytes

    # Calculate memory utilization percentage
    $memoryUtilization = (($totalMemory - $memoryAverage) / $totalMemory) * 100

    # Add the result to the collection
    $results += [PSCustomObject]@{
        VMName = $vmName
        ResourceGroup = $resourceGroupName
        CPUUtilization = [math]::Round($cpuAverage, 2)
        MemoryUtilization = [math]::Round($memoryUtilization, 2)
    }
}

# Output the results
$results | Format-Table -AutoSize
