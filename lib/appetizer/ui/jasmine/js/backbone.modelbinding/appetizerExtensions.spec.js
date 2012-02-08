describe("appetizer-ui extensions", function(){
  beforeEach(function(){
    this.model = new AModel({
      villain: "mrMonster",
      niceDude: "Dr No",
      pet: { smelly: "dog" }
    });
    this.model.villain = function () { return "Le Grand Mechant Loup" };
    this.model.niceDude = "James Bond";
    this.model.country = new AModel({ 
      withFood: { hasWine: "France" } 
    });
    this.view = new AppetizerView({model: this.model});
    this.view.render();
  });

  it("grabs attribute from methods, if existing", function(){
    var el = $(this.view.el).find("#villain");
    expect(el.text()).toBe("Le Grand Mechant Loup");
  });

  it("grabs attribute from values, if existing", function(){
    var el = $(this.view.el).find("#mrNice");
    expect(el.text()).toBe("James Bond");
  });

  it("grabs attribute from object attributes.", function(){
    var el = $(this.view.el).find("#pet");
    expect(el.text()).toBe("dog");
  });

  it("sets attribute from object attributes.", function(){
    var el = this.view.$("#cat");
    el.val("cat");
    el.trigger("change");

    expect(this.model.get("pet").smelly).toBe("dog");
    expect(this.model.get("pet").fluffy).toBe("cat");
  });

  it("grabs attribute from associated models.", function(){
    var el = $(this.view.el).find("#country");
    expect(el.text()).toBe("France");
  });

  it("sets attribute from associated objects.", function(){
    var el = this.view.$("#usa");
    el.val("USA");
    el.trigger("change");

    expect(this.model.country.get("withFood").hasWine).toBe("France");
    expect(this.model.country.get("withFood").hasBurgers).toBe("USA");
  });
});
