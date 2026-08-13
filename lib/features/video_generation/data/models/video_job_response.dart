class GenerateVideoJobResponse {
  final String jobId;
  final String status;
  final int cost; // 40 or 50
  final String createdAt;

  GenerateVideoJobResponse({
    required this.jobId,
    required this.status,
    required this.cost,
    required this.createdAt,
  });

  factory GenerateVideoJobResponse.fromJson(Map<String, dynamic> json) {
    return GenerateVideoJobResponse(
      jobId: json['jobId'] ?? json['job_id'] ?? '',
      status: json['status'] ?? 'pending',
      cost: json['cost'] is int ? json['cost'] : int.tryParse(json['cost']?.toString() ?? '40') ?? 40,
      createdAt: json['createdAt'] ?? json['created_at'] ?? '',
    );
  }
}
