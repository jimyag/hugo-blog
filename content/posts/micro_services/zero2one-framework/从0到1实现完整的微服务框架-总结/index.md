---
title: "从0到1实现完整的微服务框架 总结"
date: 2022-04-18T09:20:02+08:00
draft: false
slug: /038c7636
tags: ["微服务","gRPC"]
categories: ["微服务","gRPC"]
featured: false 
comment: false 
toc: true 
diagram: true 
series: [ "从0到1实现完整的微服务框架" ] 
pinned: false
weight: 100
---

这一段时间又重构了之前的代码，这时候代码和项目的结构发生了很大的变化。

<!--more-->

## 重构的原因

在使用多个`go.mod`管理不同项目的时候，所有的项目是在同一个仓库里面，这个是之后重构不下去了的目录

```powershell
├─api
│  └─user-api
├─common
│  ├─proto
│  └─util
├─docs
│  └─service
├─goods
│  ├─api
│  ├─common
│  │  └─proto
│  └─srv
├─order
│  ├─api
│  ├─common
│  │  └─proto
│  └─srv
├─service
│  ├─inventory_srv
│  ├─order_srv
│  └─user_srv
└─user
    ├─api
    └─rpc
```

在最开始的时候是每个服务是这样的的

```powershell
shop
├── api
│   └── user-api	// 用户服务的api 
│   └── goods-api	// 商品的api 
...
├── docs
│   └── service
└── service
    └── user-srv
    └── goods-srv

```

把api和rpc 服务分开，每一个api和rpc服务都有一个`go.mod`但是在遇到rpc服务之间相互调用的时候就会出现循环引用的问题。这时候出现了第一次重构。

### 第一次重构

将每个服务单独分开分为`rpc-common-api`，目录结构如下

```powershell
├─goods
│  ├─api
│  ├─common
│  │  └─proto
│  └─srv
├─order
│  ├─api
│  ├─common
│  │  └─proto
│  └─srv
```

这次使用了`workspace`的新特性，管理起来确实很方便，但是还是存在上述的循环引用的问题，并且当时的`golond`还没有完美适配`1.18`的新特性，只能使用beta版。之前了解过`go-zero`微服务的框架，看到他们有一个`go-zero-looklook`的项目，看到了里面的目录结构，在与`go-zero-looklook`的作者聊了之后发现微服务在使用多个仓库和一个仓库的优点和缺点，最后还是选择使用一个仓库一个`go.mod`进行管理，这样虽然又与平常的单体项目看起来差不多了，但是他其实还是微服务项目。

### 第二次重构

```powershell
├─app
│  ├─goods
│  │  ├─api
│  │  └─rpc
│  ├─inventory
│  │  └─rpc
│  ├─order
│  │  ├─api
│  │  └─rpc
│  └─user
│      ├─api
│      └─rpc
├─common
│  ├─model
│  ├─proto
│  └─utils
├─deploy
└─docs
```

以下的项目结构对于个人开发一个微服务来说很友好，

1. 方便管理，只有一个`go.mod`一个仓库，不用一直拉新的仓库之类的
2. 不会出现循环引用的问题，所有的proto都放在了`common`中，如果要想修改proto，在common中修改之后所有用到的服务都会知道，
3. rpc服务之间互相调用的时候要用到别的proto文件，这样只需要从公共中引用就行，在之前要不就复制一份到要用的服务中，但是这会产生proto的更新不及时的问题，
4. 之前所有的公共的方法都是在每一个服务中，如果这个公共的方法更新之后，所有地方都要进行修改。将公共的方法等放在一起就不会出现这种问题，而且这样也能减少代码行数，之前的代码有`3.1w`行，而现在的代码只有`1.4w`行

## 项目的服务介绍

### 用户服务

用户服务主要是用来做登录鉴权。这里没有什么难点主要是使用了PASETO鉴权没有使用平常的JWT的token验证。

```sql
CREATE TABLE "user"
(
    "id"         bigserial PRIMARY KEY,
    "created_at" timestamptz    NOT NULL DEFAULT (now()),
    "updated_at" timestamptz    NOT NULL DEFAULT (now()),
    "deleted_at" timestamptz             DEFAULT null,
    "email"      varchar UNIQUE NOT NULL,
    "password"   varchar        NOT NULL,
    "nickname"   varchar        NOT NULL,
    "gender"     varchar(6)     NOT NULL DEFAULT 'male',
    "role"       int8           NOT NULL DEFAULT 1
);
```

### 商品服务

商品服务提供了商品的信息的增删改查。数据表设计的也很简单

```sql
CREATE TABLE "goods"
(
    "id"         bigserial PRIMARY KEY,
    "created_at" timestamptz NOT NULL DEFAULT (now()),
    "updated_at" timestamptz NOT NULL DEFAULT (now()),
    "deleted_at" timestamptz          DEFAULT null,
    "name"       varchar     NOT NULL,
    "price"      float       NOT NULL
);

CREATE INDEX ON "goods" ("name");
```

同时它也提供如下服务。

```protobuf
service goods{
  // 商品
  rpc CreateGoods(CreateGoodRequest)returns(GoodsInfo); // 创建商品
  rpc UpdateGoods(GoodsInfo)returns(GoodsInfo); // 更新商品信息
  rpc GetGoods(GoodID)returns(GoodsInfo); // 获得商品信息
  rpc DeleteGoods(GoodsInfo)returns(Empty);// 删除good信息
  rpc GetGoodsBatchInfo(ManyGoodsID)returns(ManyGoodsInfos);//批量获得商品信息
}
```

### 库存服务

对于淘宝和京东这样的大型商城而言，对于一个商品可能在不同的地方都有库存，我们下单之后会选择就近的一个发货。同样的，这里的库存服务也是这样的，

此项目做了简化只包含了关键的商品的id和数量，后面的商品出售的细节是在创建订单相关的服务中起作用的。这里先不做介绍。

```sql
CREATE TABLE "inventory"
(
    "id"         bigserial PRIMARY KEY,
    "created_at" timestamptz NOT NULL DEFAULT (now()),
    "updated_at" timestamptz NOT NULL DEFAULT (now()),
    "deleted_at" timestamptz          DEFAULT null,
    "goods_id"   integer     NOT NULL,
    "sticks"     integer     NOT NULL,
    "version"    integer     NOT NULL
);

CREATE INDEX ON "inventory" ("goods_id");

create type GoodsDetail as
(
    goods_id integer,
    nums     integer
);


create table stock_sell_detail
(
    "order_id" int8          not null primary key,
    "status"   int2          not null,
    "detail"   GoodsDetail[] not null
);

CREATE UNIQUE INDEX ON "stock_sell_detail" ("order_id");
```

库存服务提供的服务

```protobuf
service inventory{
  rpc SetInv(GoodInvInfo) returns(Empty);// 设置库存
  rpc InvDetail(GoodInvInfo) returns(GoodInvInfo);// 获取库存信息
  rpc Sell(SellInfo)returns(Empty) ; // 库存扣减
  rpc Rollback(SellInfo) returns(Empty);// 归还库存
}
```

#### 注意事项

1. 设置库存的时候一定要确保该商品以及存在了
2. 库存扣减的时候一定要确保所有的商品都可以购买成功，如果有一个不能购买成功的都要退回失败。
3. 归还库存的时候一定要确保不能归还这也是第二张表的作用，确保不会重复归还。

### 订单服务

订单服务是此项目中最重要也是最复杂的一个服务。

```sql
CREATE TABLE "shopping_cart"
(
    "id"         bigserial PRIMARY KEY,
    "created_at" timestamptz NOT NULL DEFAULT (now()),
    "updated_at" timestamptz NOT NULL DEFAULT (now()),
    "deleted_at" timestamptz          DEFAULT null,
    "user_id"    integer     NOT NULL,
    "goods_id"   integer     NOT NULL,
    "nums"       integer     NOT NULL,
    "checked"    boolean     NOT NULL
);

CREATE TABLE "order_info"
(
    "id"            bigserial PRIMARY KEY,
    "created_at"    timestamptz NOT NULL DEFAULT (now()),
    "updated_at"    timestamptz NOT NULL DEFAULT (now()),
    "deleted_at"    timestamptz          DEFAULT null,
    "user_id"       integer     NOT NULL,
    "order_id"      int8 UNIQUE NOT NULL,
    "pay_type"      varchar,
    "status"        int2        NOT NULL, -- 1 待支付 2 成功 3 超时关闭
    "trade_id"      varchar,              --支付编号
    "order_mount"   float,                -- 订单金额
    "pay_time"      timestamptz,
    "address"       varchar     NOT NULL,
    "signer_name"   varchar(40) NOT NULL,
    "signer_mobile" varchar(20) NOT NULL,
    "post"          varchar     NOT NULL
);

CREATE TABLE "order_goods"
(
    "id"          bigserial PRIMARY KEY,
    "created_at"  timestamptz NOT NULL DEFAULT (now()),
    "updated_at"  timestamptz NOT NULL DEFAULT (now()),
    "deleted_at"  timestamptz          DEFAULT null,
    "order_id"    int8        NOT NULL,
    "goods_id"    integer     NOT NULL,
    "goods_name"  varchar     NOT NULL,
    "goods_price" float       NOT NULL,
    "nums"        integer     NOT NULL
);
CREATE INDEX ON "shopping_cart" ("user_id");
CREATE INDEX ON "shopping_cart" ("goods_id");
CREATE INDEX ON "order_info" ("user_id");
CREATE INDEX ON "order_info" ("order_id");
CREATE INDEX ON "order_goods" ("order_id");
CREATE INDEX ON "order_goods" ("goods_id");
CREATE INDEX ON "order_goods" ("goods_name");
```

其中包括订单的信息、购物车的信息、订单中商品的信息。

购物车的就是简单的增删改查，只要注意一下保证有就行。

除了创建订单也没有什么要注意的。

#### 创建订单

1. 首先发送一个要归还库存的半消息

   创建订单的方法中

   ```go
   orderlistener := NewOrderListener(server, ctx)
   	p, err := rocketmq.NewTransactionProducer(
   		orderlistener,
   		producer.WithNameServer([]string{"192.168.0.2:9876"}),
   	)
   // 处理错误
   	if err != nil {
   		global.Logger.Error("创建生产者失败", zap.Error(err))
   		return &proto.OrderInfo{}, status.Error(codes.Internal, "创建生产者失败")
   	}
   	err = p.Start()
   // 启动
   	if err != nil {
   		global.Logger.Error("启动生产者失败", zap.Error(err))
   		return &proto.OrderInfo{}, status.Error(codes.Internal, "启动生产者失败")
   	}
   	topic := "order_reback"
   
   	// 一定要在这边生成订单号
   	createOrderParams := model.CreateOrderParams{
   		UserID:       req.UserID,
   		OrderID:      generate.GenerateOrderID(req.UserID),
   		Status:       1, // 1 待支付 2 成功 3 超时关闭
   		Address:      req.Address,
   		SignerName:   req.Name,
   		SignerMobile: req.Mobile,
   		Post:         req.Post,
   	}
   // struct 序列化为[]byte
   	jsonString, err := json.Marshal(createOrderParams)
   	if err != nil {
   		global.Logger.Error("序列化失败", zap.Error(err))
   		return &proto.OrderInfo{}, status.Error(codes.Internal, "序列化失败")
   	}
   	res, err := p.SendMessageInTransaction(
   		ctx,
   		primitive.NewMessage(
   			topic,
   			jsonString,
   		),
   	)
   ```

2. 执行本地的事务

      ```go
      // 本地事务的监听
      type OrderListener struct {
      	Code        codes.Code
      	Detail      string
      	OrderID     int64
      	OrderAmount float32
      	server      *OrderServer
      	ctx         context.Context
      }
      
      func NewOrderListener(server *OrderServer, ctx context.Context) *OrderListener {
      	return &OrderListener{
      		server: server,
      		ctx:    ctx,
      	}
      }
      func (dl *OrderListener) ExecuteLocalTransaction(msg *primitive.Message) primitive.LocalTransactionState {
      	// 4. 从购物车中拿到选中的商品
      	// 1. 商品的金额自己查询 商品服务
      	// 2. 库存的扣减 库存服务
      	// 3. 订单的基本信息表
      	//
      	// 5. 从购物车中删除已购买的记录
      	// 从购物车中拿到选中的商品
      	createOrderParams := model.CreateOrderParams{}
      	err := json.Unmarshal(msg.Body, &createOrderParams)
      	if err != nil {
      		global.Logger.Error("解析消息失败", zap.Error(err))
      		return primitive.RollbackMessageState
      	}
      
      	getCheckedCart := model.GetCartListCheckedParams{
      		UserID:  createOrderParams.UserID,
      		Checked: true,
      	}
      	goodsIDS := make([]*proto.GoodID, 0)
      	shoppingCart, err := dl.server.Store.GetCartListChecked(dl.ctx, getCheckedCart)
      	if shoppingCart == nil {
      		dl.Code = codes.InvalidArgument
      		dl.Detail = "购物车为空"
      		return primitive.RollbackMessageState
      	} else if err != nil {
      		dl.Code = codes.Internal
      		dl.Detail = "获取购物车失败"
      		return primitive.RollbackMessageState
      	}
      
      	// 保存 商品的数量
      	goodsNumMap := make(map[int32]int32)
      	for _, cart := range shoppingCart {
      		goodsIDS = append(goodsIDS, &proto.GoodID{Id: cart.GoodsID})
      		goodsNumMap[cart.GoodsID] = cart.Nums
      	}
      	goodsInfos, err := global.GoodsClient.GetGoodsBatchInfo(dl.ctx, &proto.ManyGoodsID{GoodsIDs: goodsIDS})
      	if err != nil {
      		dl.Code = codes.Internal
      		dl.Detail = "获取商品信息失败"
      		return primitive.RollbackMessageState
      	}
      
      	// 订单的总金额
      	var orderAmount float32
      	// 订单中商品的参数
      	createOrderGoodsParams := make([]*model.CreateOrderGoodsParams, 0)
      	// 扣减库存 的参数
      	sellInfo := proto.SellInfo{GoodsInfo: make([]*proto.GoodInvInfo, 0)}
      	for _, datum := range goodsInfos.Data {
      		// 求总金额
      		orderAmount += datum.Price * float32(goodsNumMap[datum.Id])
      		// 订单中的参数
      		createOrderGoodsParams = append(createOrderGoodsParams, &model.CreateOrderGoodsParams{
      			GoodsID:    datum.Id,
      			GoodsName:  datum.Name,
      			GoodsPrice: float64(datum.Price),
      			Nums:       goodsNumMap[datum.Id],
      		})
      		// 扣减库存的参数
      		sellInfo.GoodsInfo = append(sellInfo.GoodsInfo, &proto.GoodInvInfo{
      			GoodsId: datum.Id,
      			Num:     goodsNumMap[datum.Id],
      		})
      	}
      
      	// 跨服务调用 扣减库存
      
      	_, err = global.InventoryClient.Sell(dl.ctx, &sellInfo)
      	if err != nil {
      		// todo
      		// 如果是因为网络问题，这种如何避免
      		// sell 的返回逻辑 返回的状态码是否sell返回的状态码 如果是才进行rollback
      		dl.Code = codes.ResourceExhausted
      		dl.Detail = "扣减库存失败"
      		return primitive.RollbackMessageState
      	}
      
      	// 本地服务的事务
      	err = dl.server.Store.ExecTx(dl.ctx, func(queries *model.Queries) error {
      		createOrderParams.OrderMount = sql.NullFloat64{
      			Float64: float64(orderAmount),
      			Valid:   true,
      		}
      		// 保存order
      		_, err = dl.server.Store.CreateOrder(dl.ctx, createOrderParams)
      		if err != nil {
      			dl.Code = codes.Internal
      			dl.Detail = "保存订单失败"
      			return err
      		}
      		dl.OrderAmount = orderAmount
      
      		// 将订单id更新
      		for _, good := range createOrderGoodsParams {
      			good.OrderID = createOrderParams.OrderID
      		}
      		// 批量插入订单中的商品
      		err = dl.server.Store.ExecTx(dl.ctx, func(queries *model.Queries) error {
      			for _, good := range createOrderGoodsParams {
      				_, err = queries.CreateOrderGoods(dl.ctx, *good)
      				if err != nil {
      					dl.Code = codes.Internal
      					dl.Detail = "保存订单商品失败"
      					return err
      				}
      			}
      			return nil
      		})
      		if err != nil {
      			return err
      		}
      
      		// 批量删除购物车中记录
      		err = dl.server.Store.ExecTx(dl.ctx, func(queries *model.Queries) error {
      			for _, cart := range shoppingCart {
      				_, err = queries.DeleteCartItem(dl.ctx, model.DeleteCartItemParams{
      					DeletedAt: sql.NullTime{Time: time.Now(), Valid: true},
      					UserID:    cart.UserID,
      					GoodsID:   cart.GoodsID,
      				})
      				if err != nil {
      					dl.Code = codes.Internal
      					dl.Detail = "删除购物车中商品失败"
      					return err
      				}
      			}
      			return nil
      		})
      		if err != nil {
      			return err
      		}
      		return nil
      	})
      	// 如果有错就要把库存归还
      	if err != nil {
      		return primitive.CommitMessageState
      	}
      	return primitive.RollbackMessageState
      }
      ```

      1. 从购物车中拿到已经选中的商品
         1. 购物车中没有商品就说明这个消息是没有作用的可以抛弃
         2. 获取购物车失败就重试
      2. 批量处理获得的购物车的商品的信息
         1. 获取失败就重试
      3. 计算订单需要多钱
      4. 生成扣减库存的参数
      5. 扣减库存
         1. 因为网络问题的扣减失败，生成的错误码肯定不是在库存服务中sell接口中的错误参数，只要判断不是sell接口中的参数就可以判断是网络或者宕机造成的。如果是了就可以让他重试
         2. 由于某个商品扣减失败了而造成错误，那么所有的都应该回滚。目前系统设计的是这样的。
      6. 开始执行本地事务了。
      7. 保存订单信息
         1. 保存失败，归还库存
      8. 保存订单中的商品信息
         1. 保存失败，归还库存，
      9. 如果所有的都成了，就撤销归还库存的消息。
      
3. 本地消息的回查

      ```go
      func (dl *OrderListener) CheckLocalTransaction(msg *primitive.MessageExt) primitive.LocalTransactionState {
      	createOrderParams := model.CreateOrderParams{}
      	err := json.Unmarshal(msg.Body, &createOrderParams)
      	if err != nil {
      		global.Logger.Error("解析消息失败", zap.Error(err))
      		return primitive.RollbackMessageState
      	}
      
      	_, err = dl.server.GetOrderDetail(dl.ctx, &proto.GetOrderDetailRequest{OrderID: createOrderParams.OrderID})
      	if err != nil {
      		// 没有扣减的库存不能被归还
      		return primitive.CommitMessageState
      	}
      	return primitive.RollbackMessageState
      }
      ```

      判断订单是否被创建成功了，如果创建成功了，就说明不用归还库存了。

      如果没有创建成功，就说明要归还原有的库存。

4. 库存服务监听reback的消息

      库存的main方法

      ```go
      // 监听库存归还的topic
      	c, _ := rocketmq.NewPushConsumer(
      		consumer.WithNameServer([]string{"192.168.0.2:9876"}),
      		consumer.WithGroupName("inventory-group"))
      
      	if err = c.Subscribe("order_reback", consumer.MessageSelector{},handler.AutoRollBack); err != nil {
      		global.Logger.Error("订阅库存归还消息失败", zap.Error(err))
      	}
      
      ```

      回调函数的实现

      ```go
      func AutoRollBack(ctx context.Context, msgs ...*primitive.MessageExt) (consumer.ConsumeResult, error) {
         type OrderInfo struct {
            OrderID int64 `json:"order_id"`
         }
         for _, msg := range msgs {
            // 既然要归还库存，就应该直到每件商品应该归还多少， 这时候出现 重复归还的问题
            // 这个接口应该保证幂等性，不能因为消息的重复发送而导致一个订单的库存归还多次，没有扣减的库存不能归还。
            // 新建一张表，记录了详细的订单扣减细节，以及归还的情况
            var orderInfo OrderInfo
            err := json.Unmarshal(msg.Body, &orderInfo)
            if err != nil {
               global.Logger.Error("JSON 解析失败", zap.Error(err))
               // 根据业务来，如果赶紧时自己代码问题就用
               //return consumer.ConsumeRetryLater,nil
               // 否则就直接忽略这个消息
               return consumer.ConsumeSuccess, nil
            }
            // 将inv的库存加回去，同时将sell status 变为2
            // todo
            _, err = global.DB.Begin()
            if err != nil {
               global.Logger.Error("获得事务失败", zap.Error(err))
               return consumer.ConsumeRetryLater, nil
            }
      
            // 将状态变为2
         }
         return consumer.ConsumeSuccess, nil
      }
      
      ```

      1. 拿到消息，这里拿到的消息都是要被归还的
      2. 解析消息，拿到订单号
      3. 将所有的库存全加回去
         1. 加失败了就重试
      4. 将状态变为2表示已归还，这里应该保证幂等性，已经归还的不能再此被归还，也就是状态为1的才可以继续被归还。
      5. 确定消费成功。

5. 其他

      对于inventory中的sell接口，在sell时一定要保证创建一条`stock_sell_detail`记录来保证之后归还的时候可以使用。

## 踩坑

1. 先考虑能不能跑通再考虑效率的问题。用orm没有错的，首先是解决了问题，其次是效率。

