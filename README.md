# O-Captain-My-Captain

# 개발 환경 설정
## 필요 요건
* `vagrant` 설치
* `virtualbox` 설치

## 프로젝트 시작
* `git clone git@github.com:hyunsuk/O-Captain-My-Captain.git`
* `vagrant` 디렉토리로 이동 후 `vagrant up`
* `vagrant up` 이 끝나면 vm 접속 후 아래의 명령어 실행

```shell
$ cd ~
$ python migrate
$ python manage runserver 0:8000
```