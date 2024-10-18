# EC2 AutoScaling Group Lifecycle Hooks Controller

이 프로젝트는 EC2 AutoScaling Group (ASG) Lifecycle Hooks를 제어하는 AWS Lambda 함수를 포함하고 있습니다. 이 함수는 EC2 인스턴스의 시작 및 종료 이벤트를 처리하며, SSM, EC2, S3, AutoScaling과 같은 AWS 서비스를 사용하여 EC2 인스턴스의 생명주기 단계에 따라 명령을 실행합니다.

## 개요

Lambda 함수는 EC2 AutoScaling 그룹에서 발생하는 생명주기 액션을 처리합니다:

- **EC2 인스턴스 시작 (Launch)**
- **EC2 인스턴스 종료 (Terminate)**

함수는 AWS **SSM (Systems Manager)**을 사용하여 각 생명주기 단계에서 EC2 인스턴스에 미리 정의된 명령을 실행하고, 명령 실행 후에는 AutoScaling Group의 생명주기 훅을 완료합니다.

## 주요 기능

- **인스턴스 시작 시 처리**: EC2 인스턴스가 시작될 때 미리 정의된 SSM 문서(`EC2_LifeCycleHooks_At_Launch`)를 실행합니다.
- **인스턴스 종료 시 처리**: EC2 인스턴스가 종료될 때 SSM 문서(`EC2_LifeCycleHooks_At_Terminate`)를 실행하며, 인스턴스의 태그 정보에 따라 동적으로 S3 버킷과 로그 경로를 설정합니다.
- **생명주기 완료**: 모든 명령이 완료된 후 AutoScaling Group의 생명주기 액션을 `CONTINUE`로 완료 처리합니다.

## Lambda 함수 동작 방식

1. **EC2 인스턴스 시작**:
   - EC2 인스턴스가 시작될 때 해당 인스턴스에 SSM 명령을 전송하여 설정된 작업을 수행합니다.
   
2. **EC2 인스턴스 종료**:
   - EC2 인스턴스가 종료될 때 인스턴스 태그에 따라 로그 경로와 S3 버킷을 설정하고 SSM 명령을 전송합니다.
   
3. **Waiter 사용**:
   - SSM 명령이 성공적으로 완료될 때까지 대기한 후, AutoScaling Group 생명주기 액션을 완료합니다.

## 설치 및 배포

1. **Lambda 함수 배포**:
   - Lambda 함수와 관련된 코드를 AWS Lambda에 배포합니다.
   
2. **AWS 리소스 준비**:
   - 필요한 AWS 리소스(S3, SSM 문서 등)를 준비하고 설정합니다.
   
3. **Lambda 트리거 설정**:
   - AutoScaling Group Lifecycle Hooks를 Lambda 트리거로 설정합니다.

## 필요 사항

- AWS 계정
- IAM 권한 (Lambda, SSM, AutoScaling, S3 등)

## 참고 문서

- [AWS Lambda](https://aws.amazon.com/lambda/)
- [AWS Systems Manager](https://aws.amazon.com/systems-manager/)
- [AWS Auto Scaling](https://aws.amazon.com/autoscaling/)

